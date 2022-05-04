(* This file contains proofs of the floating point properties:
local and global error, finiteness *)

From vcfloat Require Import FPLang FPLangOpt RAux Rounding Reify Float_notations Automate.
Require Import IntervalFlocq3.Tactic.
Import Binary.
Import List ListNotations.
Set Bullet Behavior "Strict Subproofs".

Require Import float_model real_model real_lemmas vcfloat_lemmas matrix_analysis.

Open Scope R_scope.

Section WITHNANS.

Context {NANS: Nans}.

Lemma prove_roundoff_bound_q:
  forall pq : state,
  prove_roundoff_bound leapfrog_bmap (leapfrog_vmap pq) q' 
    (1.235*(1/10^7)).
Proof.
intros [p q].
prove_roundoff_bound.
- abstract (prove_rndval; interval).
- prove_roundoff_bound2.
 match goal with |- Rabs ?a <= _ => field_simplify a end.
interval.
Qed.

Lemma prove_roundoff_bound_p:
  forall pq : state,
  prove_roundoff_bound leapfrog_bmap (leapfrog_vmap pq) p' 
   (6.552*(1/10^8)).
Proof.
intros [p q].
prove_roundoff_bound.
- abstract (prove_rndval; interval).
- prove_roundoff_bound2.
match goal with |- Rabs ?a <= _ => field_simplify a end.
interval.
Qed.


Lemma prove_roundoff_bound_q_implies:
  forall pq : state,
  boundsmap_denote leapfrog_bmap (leapfrog_vmap pq)-> 
  Rabs (FT2R (fval (env_ (leapfrog_vmap pq)) q') 
           - rval (env_ (leapfrog_vmap pq)) q')
        <= (1.235*(1/10^7))
.
Proof.
intros.
apply (prove_roundoff_bound_q pq H).
Qed.

Lemma prove_roundoff_bound_p_implies:
  forall pq : state,
  boundsmap_denote leapfrog_bmap (leapfrog_vmap pq)-> 
  Rabs (FT2R (fval (env_ (leapfrog_vmap pq)) p')  
      - rval (env_ (leapfrog_vmap pq)) p') <= (6.552*(1/10^8))
.
Proof.
intros.
apply (prove_roundoff_bound_p pq H).
Qed.

Ltac unfold_all_fval :=  (* move this to vcfloat *)
 repeat
  match goal with
  | |- context [fval (env_ ?e) ?x] =>
     pattern (fval (env_ e) x);
     let M := fresh in match goal with |- ?MM _ => set (M := MM) end;
     unfold fval; try unfold x; unfold type_of_expr; unfold_fval;
    repeat match goal with |- context [env_ ?a ?b ?c] => 
       let u := constr:(env_ a b c) in 
       let u1 := eval hnf in u in
      change u with u1
     end;
    subst M; cbv beta
end.

Lemma itern_implies_bmd_aux:
  forall pq0 : state,
  forall n : nat,
  boundsmap_denote leapfrog_bmap 
  (leapfrog_vmap (iternF pq0 n)) ->
  (is_finite _ _  (fst(iternF pq0 (S n))) = true) /\
  (is_finite _ _  (snd(iternF pq0 (S n))) = true).
Proof.
intros.
rewrite step_iternF.
destruct (iternF pq0 n) as [p q]; clear pq0 n.
split.
-
destruct (prove_roundoff_bound_p _ H) as [? _]; clear H.
rewrite <- H0; clear H0.
simple apply f_equal.
unfold_all_fval.
reflexivity.
-
destruct (prove_roundoff_bound_q _ H) as [? _]; clear H.
rewrite <- H0; clear H0.
simple apply f_equal.
unfold_all_fval.
reflexivity.
Qed.

Definition local_round_off :=  ∥(1.235*(1/10^7) , 6.552*(1/10^8))∥.




End WITHNANS.