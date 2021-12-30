From Flocq Require Import Binary Bits Core.
From compcert.lib Require Import IEEE754_extra Coqlib Floats Zbits Integers.

Require Import float_lib.

Require vcfloat.Test.
Require Import vcfloat.FPLang.
Require Import vcfloat.FPLangOpt.

Definition SterbenzSub32 := Float32.sub.
Definition SterbenzSub := Float.sub.

Definition placeholder32: AST.ident -> float32. intro. apply Float32.zero. Qed.

Module B_Float_Notations.

Declare Scope float1_scope.
Delimit Scope float1_scope with F1.
Declare Scope float2_scope.
Delimit Scope float2_scope with F2.

Notation "x + y" := (Bplus (fprec Tsingle) (femax Tsingle) eq_refl eq_refl (plus_nan _) mode_NE x y) (at level 50, left associativity) : float1_scope.
Notation "x - y"  := (Bminus (fprec Tsingle) (femax Tsingle) eq_refl eq_refl (plus_nan _) mode_NE x y) (at level 50, left associativity) : float1_scope.
Notation "x * y"  := (Bmult (fprec Tsingle) (femax Tsingle) eq_refl eq_refl (mult_nan _) mode_NE x y) (at level 40, left associativity) : float1_scope.
Notation "x / y"  := (Bdiv (fprec Tsingle) (femax Tsingle) eq_refl eq_refl (div_nan _) mode_NE x y) (at level 40, left associativity) : float1_scope.
Notation "- x" := (Bopp (fprec Tsingle) (femax Tsingle) (opp_nan _) x) (at level 35, right associativity) : float1_scope.

Notation "x + y" := (Bplus (fprec Tdouble) (femax Tdouble) eq_refl eq_refl (plus_nan _) mode_NE x y) (at level 50, left associativity) : float2_scope.
Notation "x - y"  := (Bminus (fprec Tdouble) (femax Tdouble) eq_refl eq_refl (plus_nan _) mode_NE x y) (at level 50, left associativity) : float2_scope.
Notation "x * y"  := (Bmult (fprec Tdouble) (femax Tdouble) eq_refl eq_refl (mult_nan _) mode_NE x y) (at level 40, left associativity) : float2_scope.
Notation "x / y"  := (Bdiv (fprec Tdouble) (femax Tdouble) eq_refl eq_refl (div_nan _) mode_NE x y) (at level 40, left associativity) : float2_scope.
Notation "- x" := (Bopp (fprec Tdouble) (femax Tdouble) (opp_nan _) x) (at level 35, right associativity) : float2_scope.

End B_Float_Notations.


Ltac ground_pos p := 
 match p with
 | Z.pos ?p' => ground_pos p'
 | xH => constr:(tt) 
 | xI ?p' => ground_pos p' 
 | xO ?p' => ground_pos p' 
 end.

Ltac find_type prec emax :=
 match prec with
 | 24%Z => match emax with 128%Z => constr:(Tsingle) end
 | 53%Z => match emax with 1024%Z => constr:(Tdouble) end
 | Z.pos ?precp => 
     let g := ground_pos precp in let g := ground_pos emax in 
     constr:(TYPE precp emax (ZLT_intro prec emax (eq_refl _)) (BOOL_intro _ (eq_refl _)))
 end.

Definition Zconst (t: type) : Z -> ftype t :=
  BofZ (fprec t) (femax t) (Pos2Z.is_pos (fprecp t)) (fprec_lt_femax t).

Ltac reify_float_expr E :=
 match E with
 | placeholder32 ?i => constr:(@Var AST.ident Tsingle i)
 | cast ?tto _ ?f => constr:(@Unop AST.ident (CastTo tto None) f)
 | BofZ ?prec ?emax _ _ ?z => let t := find_type prec emax in
                                                 constr:(@Const AST.ident t (Zconst t z))
 | BofZ (fprec ?t) _ _ _ ?z => constr:(@Const AST.ident t (Zconst t z))
 | Zconst ?t ?z => constr:(@Const AST.ident t (Zconst t z))
 | BofZ _ _ _ _ => fail 1 "reify_float_expr failed on" E "because the prec,emax arguments must be either integer literals or of the form (fprec _),(femax _)"
 | Bplus _ _ _ _ mode_NE ?a ?b => let a' := reify_float_expr a in let b' := reify_float_expr b in 
                                      constr:(@Binop AST.ident (Rounded2 PLUS None) a' b')
 | Bminus _ _ _ _ mode_NE ?a ?b => let a' := reify_float_expr a in let b' := reify_float_expr b in 
                                      constr:(@Binop AST.ident (Rounded2 MINUS None) a' b')
 | Bmult _ _ _ _ mode_NE ?a ?b => let a' := reify_float_expr a in let b' := reify_float_expr b in 
                                      constr:(@Binop AST.ident (Rounded2 MINUS None) a' b')
 | Bdiv _ _ _ _ mode_NE ?a ?b => let a' := reify_float_expr a in let b' := reify_float_expr b in 
                                      constr:(@Binop AST.ident (Rounded2 MINUS None) a' b')
 | Bopp _ _ _ ?a => let a' := reify_float_expr a in 
                                      constr:(@Unop AST.ident (Exact1 Opp) a')
 | Babs _ _ _ ?a => let a' := reify_float_expr a in 
                                      constr:(@Unop AST.ident (Exact1 Abs) a')
 | Float.of_single ?f => constr:(@Unop AST.ident (CastTo Tdouble None) f)
 | Float.to_single ?f => constr:(@Unop AST.ident (CastTo Tsingle None) f)
 | float32_of_Z ?n => constr:(@Const AST.ident Tsingle (float32_of_Z n))
 | Float32.of_int ?i => constr:(@Const AST.ident Tsingle (float32_of_Z (Int.signed i)))
 | Float32.of_intu ?i => constr:(@Const AST.ident Tsingle (float32_of_Z (Int.unsigned i)))
 | Float32.of_long ?i => constr:(@Const AST.ident Tsingle (float32_of_Z (Int64.signed i)))
 | Float32.of_longu ?i => constr:(@Const AST.ident Tsingle (float32_of_Z (Int64.unsigned i)))
 | Float32.mul ?a ?b => let a' := reify_float_expr a in let b' := reify_float_expr b in 
                                      constr:(@Binop AST.ident (Rounded2 MULT None) a' b')
 | Float32.div ?a ?b => let a' := reify_float_expr a in let b' := reify_float_expr b in 
                                      constr:(@Binop AST.ident (Rounded2 DIV None) a' b')
 | Float32.add ?a ?b => let a' := reify_float_expr a in let b' := reify_float_expr b in 
                                      constr:(@Binop AST.ident (Rounded2 PLUS None) a' b')
 | Float32.sub ?a ?b => let a' := reify_float_expr a in let b' := reify_float_expr b in 
                                      constr:(@Binop AST.ident (Rounded2 MINUS None) a' b')
 | SterbenzSub32 ?a ?b => let a' := reify_float_expr a in let b' := reify_float_expr b in 
                                      constr:(@Binop AST.ident SterbenzMinus a' b')
 | Float32.neg ?a => let a' := reify_float_expr a in
                                      constr:(@Unop AST.ident (Exact1 Opp) a')
 | Float32.abs ?a => let a' := reify_float_expr a in
                                      constr:(@Unop AST.ident (Exact1 Abs) a')
 | float_of_Z ?n => constr:(@Const AST.ident Tsingle (float_of_Z n))
 | Float.of_int ?i => constr:(@Const AST.ident Tsingle (float_of_Z (Int.signed i)))
 | Float.of_intu ?i => constr:(@Const AST.ident Tsingle (float_of_Z (Int.unsigned i)))
 | Float.of_long ?i => constr:(@Const AST.ident Tsingle (float_of_Z (Int64.signed i)))
 | Float.of_longu ?i => constr:(@Const AST.ident Tsingle (float_of_Z (Int64.unsigned i)))
 | Float.mul ?a ?b => let a' := reify_float_expr a in let b' := reify_float_expr b in 
                                      constr:(@Binop AST.ident (Rounded2 MULT None) a' b')
 | Float.div ?a ?b => let a' := reify_float_expr a in let b' := reify_float_expr b in 
                                      constr:(@Binop AST.ident (Rounded2 DIV None) a' b')
 | Float.add ?a ?b => let a' := reify_float_expr a in let b' := reify_float_expr b in 
                                      constr:(@Binop AST.ident (Rounded2 PLUS None) a' b')
 | Float.sub ?a ?b => let a' := reify_float_expr a in let b' := reify_float_expr b in 
                                      constr:(@Binop AST.ident (Rounded2 MINUS None) a' b')
 | SterbenzSub ?a ?b => let a' := reify_float_expr a in let b' := reify_float_expr b in 
                                      constr:(@Binop AST.ident SterbenzMinus a' b')
 | Float.neg ?a => let a' := reify_float_expr a in
                                constr:(@Unop AST.ident (Exact1 Opp) a')
 | Float.abs ?a => let a' := reify_float_expr a in
                                constr:(@Unop AST.ident (Exact1 Abs) a')
 | _ => let E' := eval red in E in reify_float_expr E'
 | _ => fail 100 "could not reify" E
 end.

Ltac HO_reify_float_expr names E :=
 lazymatch names with
 | ?n :: ?names' =>
             let Ev := constr:(E (placeholder32 n)) in 
             HO_reify_float_expr names' Ev
 | nil =>reify_float_expr E
 end.

Definition list_to_env (bindings: list (AST.ident * Values.val)) : (forall ty : type, AST.ident -> ftype ty) .
pose (m :=   Maps.PTree_Properties.of_list bindings).
intros ty i.
destruct (type_eq_dec ty Tsingle); [ | destruct (type_eq_dec ty Tdouble)].
{
subst.
destruct (Maps.PTree.get i m); [ | exact Float32.zero].
destruct v; try exact f; exact Float32.zero.
}
{
subst.
destruct (Maps.PTree.get i m); [ | exact Float.zero].
destruct v; try exact f; exact Float.zero.
}
exact (B754_zero (fprec ty) (femax ty) false).
Defined.

Ltac unfold_reflect E := 
match goal with |- context [fval (list_to_env ?L) E] =>
 pattern (fval (list_to_env L) E);
 let HIDE := fresh "HIDE" in match goal with |- ?A _ => set (HIDE:=A) end;
 let m := fresh "m" in let m' := fresh "m'" in
 set (m := list_to_env L);
 hnf in m;
 set (m' := (Maps.PTree_Properties.of_list L)) in m;
 hnf in m'; simpl in m';
 let e' := eval hnf in E in change E with e';
 cbv [fval type_of_expr type_of_unop Datatypes.id];
 repeat change (type_lub _ _) with Tsingle;
 repeat change (type_lub _ _) with Tdouble;
 repeat change (cast_lub_l Tsingle Tsingle ?x) with x;
 repeat change (cast_lub_r Tsingle Tsingle ?x) with x;
 repeat change (cast_lub_l Tdouble Tdouble ?x) with x;
 repeat change (cast_lub_r Tdouble Tdouble ?x) with x;
 cbv [fop_of_unop fop_of_exact_unop fop_of_binop fop_of_rounded_binop];
 change (BOPP Tsingle) with Float32.neg;
 change (BPLUS Tsingle) with Float32.add;
 change (BMULT Tsingle) with Float32.mul;
 change (BDIV Tsingle) with Float32.div;
 repeat match goal with |- context [m ?t ?i] =>
             let u := fresh "u" in set (u := m t i); hnf in u; subst u
 end;
 subst m' m;
 subst HIDE; cbv beta
end.

Ltac vcfloat_simplifications := 
  repeat change (type_of_expr _) with Tsingle;
  repeat change (type_of_expr _) with Tdouble;
  repeat change (type_lub _ _) with Tsingle; 
  repeat change (type_lub _ _) with Tdouble; 
  repeat change (cast_lub_l Tsingle Tsingle ?A) with A; 
  repeat change (cast_lub_l Tdouble Tdouble ?A) with A; 
  repeat change (cast_lub_r Tsingle Tsingle ?A) with A; 
  repeat change (cast_lub_r Tdouble Tdouble ?A) with A;
  repeat change (cast Tdouble Tdouble ?A) with A;
  repeat change (cast Tsingle Tsingle ?A) with A.

Ltac focus f :=
 match goal with |- context [f ?a] =>
  pattern (f a);
  match goal with |- ?b _ => 
    let h := fresh "out_of_focus" in set (h:=b) 
  end
 end.


Ltac vcfloat_partial_compute := 
  vcfloat_simplifications;
  cbv beta iota delta [fop_of_binop fop_of_unop fop_of_rounded_binop fop_of_rounded_unop]; 
  cbv beta iota delta [BMULT BDIV BPLUS BMINUS BINOP];
  repeat (set (z := fprec _); compute in z; subst z); 
  repeat (set (z := femax _); compute in z; subst z); 
  repeat match goal with |- context [float32_of_Z ?a] =>
    set (z := float32_of_Z a);
    hnf in z; subst z
  end.

Definition hide {T: Type} {x: T} := x.


Ltac simplify_B754_finite x :=
      let y := eval hnf in x in 
      match y with B754_finite ?prec ?emax ?sign ?m ?e ?p =>
        let sign' := eval compute in sign in
        let m' := eval compute in m in 
        let e' := eval compute in e in
        change x with  (B754_finite prec emax sign' m' e' (@hide _ p))
      end.

Ltac simplify_float_ops x :=
  let y:= eval compute in x in 
    change x with y
.

Ltac eqb_compute :=
repeat match goal with
| |- context [binop_eqb ?a  ?b] =>
      simplify_float_ops (binop_eqb a b)
| |- context [binary_float_eqb ?a  ?b] =>
      simplify_float_ops (binary_float_eqb a b)
end.

Ltac pow2_compute :=
repeat match goal with
| |- context [to_power_2 ?a] =>
      simplify_float_ops (to_power_2 a) 
| |- context [to_power_2_pos ?a] =>
      simplify_float_ops (to_power_2_pos a) 
| |- context [to_inv_power_2 ?a] =>
      simplify_float_ops (to_inv_power_2 a) 
end.

Ltac exact_inv_compute :=
repeat match goal with
| |- context [Bexact_inverse] =>  cbv [Bexact_inverse ]
| |- context [Pos.eq_dec ?a ?b] =>
      simplify_float_ops (Pos.eq_dec a b); cbv beta iota zeta
| |- context [Z_le_dec ?a ?b] =>
      simplify_float_ops (Z_le_dec a b); cbv beta iota zeta
end. 

Ltac vcfloat_compute := 
vcfloat_partial_compute;
repeat match goal with
| |- context [B754_finite ?prec ?emax ?sign ?m ?e ?p] =>
     lazymatch p with hide => fail | _ => idtac end;
      simplify_B754_finite (B754_finite prec emax sign m e p)
| |- context [Bdiv ?prec ?emax ?p1 ?p2 ?p3 ?mode ?a1 ?a2] =>
      simplify_B754_finite (Bdiv prec emax p1 p2 p3 mode a1 a2) 
| |- context [Bmult ?prec ?emax ?p1 ?p2 ?p3 ?mode ?a1 ?a2] =>
      simplify_B754_finite (Bmult prec emax p1 p2 p3 mode a1 a2)
| |- context [Bplus ?prec ?emax ?p1 ?p2 ?p3 ?mode ?a1 ?a2] =>
      simplify_B754_finite (Bplus prec emax p1 p2 p3 mode a1 a2)
| |- context [Bminus ?prec ?emax ?p1 ?p2 ?p3 ?mode ?a1 ?a2] =>
      simplify_B754_finite (Bminus prec emax p1 p2 p3 mode a1 a2) 
end.

Ltac simplify_fcval :=
 match goal with |- context [@FPLangOpt.fcval ?x1 ?x2 ?a] =>
     focus (@FPLangOpt.fcval x1 x2);
     let a' := eval hnf in a in change a with a';
     cbv beta fix iota zeta delta [FPLangOpt.fcval FPLangOpt.fcval_nonrec 
                    FPLangOpt.option_pair_of_options];
     vcfloat_compute;
     match goal with |- ?out_of_focus _ => subst out_of_focus; cbv beta end
 end.

Definition optimize {V: Type} {NANS: Nans} (e: expr) : expr :=
  @fshift V NANS (@fcval V NANS e).

Definition optimize_div {V: Type} {NANS: Nans} (e: expr) : expr :=
  @fshift_div V NANS (@fshift V NANS (@fcval V NANS e)).

Lemma optimize_div_type {V: Type} {NANS: Nans}:
  forall e : expr, @type_of_expr V (optimize_div e) = 
    @type_of_expr V e.
Proof.
intros;
apply (eq_trans (fshift_type_div (fshift (fcval e)))
      (eq_trans (fshift_type (fcval e)) (fcval_type e))).
Defined.

Lemma optimize_div_correct {V: Type} {NANS: Nans}:
  forall env e,
    Binary.is_nan _ _ (fval env e) = false ->
    fval env (optimize_div e) = 
      eq_rect_r ftype (fval env e) (@optimize_div_type V NANS e).
Proof.
intros. unfold optimize_div.
rewrite fshift_div_correct.
{ rewrite (@fshift_correct V NANS).
rewrite (@fcval_correct V NANS).
unfold eq_rect_r.
repeat rewrite rew_compose.
f_equal.
repeat rewrite <- eq_trans_sym_distr.
rewrite <- eq_trans_assoc.
f_equal.
}
{
pose proof fshift_div_correct' env (fshift (fcval e)).
pose proof fshift_correct' env (fcval e).
rewrite (@fcval_correct V NANS env e) in H1.
revert H0 H1.
generalize (fval env (fcval e)).
try rewrite (@fcval_type V NANS). intros.
revert H1 H2.
generalize (fval env (fshift (fcval e))).
try rewrite fshift_type. try rewrite (@fcval_type V NANS). intros.
pose proof binary_float_eqb_eq_rect_r (type_of_expr e) (type_of_expr e)  f (fval env e) eq_refl .
try rewrite H2 in H3. clear H2; symmetry in H3; apply binary_float_eqb_eq in H3. subst.
revert H1.
generalize (fval env (fshift_div (fshift (fcval e)))).
try rewrite fshift_type_div. try rewrite fshift_type. try rewrite (@fcval_type V NANS). intros.
destruct (fval env e); try discriminate.
all: destruct f; simpl in H1; try contradiction; try simpl; try reflexivity.
} 
Qed.

Ltac simplify_shift_opt E :=
  match E with 
  | optimize ?e' =>
    let e:= constr:(fshift (fcval e')) in change E with e;
    match e with | @fshift ?x1 ?x2 ?a =>
        let a' := eval hnf in a in change a with a' ;
        cbv beta fix iota zeta delta [FPLangOpt.fcval FPLangOpt.fcval_nonrec 
              FPLangOpt.option_pair_of_options];
        vcfloat_compute;
        cbv beta fix iota delta [FPLangOpt.fshift FPLangOpt.fcval_nonrec ];
        vcfloat_simplifications; eqb_compute; cbv beta iota zeta;
        pow2_compute; eqb_compute; cbv beta iota zeta 
   end
  | _ => fail 100 "expr should be optimized"
end.

Ltac simplify_shift_div_opt E  :=
  match E with 
    optimize_div ?e' =>
   let e:= constr:(fshift_div (fshift (fcval e'))) in change E with e;
   match e with | @FPLangOpt.fshift_div ?x1 ?x2 (@fshift ?x3 ?x4 ?a) =>
    let a' := eval hnf in a in change a with a' ;
    cbv beta fix iota zeta delta [FPLangOpt.fcval FPLangOpt.fcval_nonrec 
          FPLangOpt.option_pair_of_options];
    vcfloat_compute;
    cbv beta fix iota delta [FPLangOpt.fshift FPLangOpt.fcval_nonrec ];
    vcfloat_simplifications; eqb_compute; cbv beta iota zeta;
    pow2_compute; eqb_compute; cbv beta iota zeta ;
    cbv beta fix iota delta [FPLangOpt.fshift_div FPLangOpt.fcval_nonrec];
    vcfloat_simplifications; eqb_compute; cbv beta iota zeta;
    pow2_compute; vcfloat_simplifications;
    exact_inv_compute; eqb_compute; cbv beta iota zeta
  end
 end.


Module TESTING.

Local Close Scope R_scope.

Local Open Scope float32_scope.

Definition F (x : float32) : float32 := float32_of_Z(1) * x.

(* Time step*)
Definition h := float32_of_Z 1 / float32_of_Z 32.

(* Single step of the integrator*)
Definition leapfrog_step ( ic : float32 * float32) : float32 * float32 :=
  let x  := fst ic in let v:= snd ic in 
  let x' := (x + h * v) + (h * h * F x) / float32_of_Z 2 in
  let v' :=  v + (h*(F x + F x')/ float32_of_Z 2) in 
  (x', v').

Definition leapfrog_stepx := fun x v => fst (leapfrog_step (x,v)).
Definition g := fun x => F x.

Import ListNotations.
Definition _x : AST.ident := 5%positive.
Definition _v : AST.ident := 7%positive.

Definition e1 := ltac:(let e' := HO_reify_float_expr constr:([_x; _v]) leapfrog_stepx in exact e').
Definition e :=  ltac:(let e' := reify_float_expr constr:( (float32_of_Z (-1))%F32 ) in exact e').
Definition e2 := ltac:(let e' := HO_reify_float_expr constr:([_x]) F in exact e').


Goal optimize e1 = Var Tsingle _x.
  simplify_shift_opt (optimize e1).
Abort.

Goal optimize_div e1 = Var Tsingle _x.
  simplify_shift_div_opt (optimize_div e1).
Abort.


End TESTING.