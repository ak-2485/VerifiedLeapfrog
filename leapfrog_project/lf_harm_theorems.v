(* This file contains proofs of the floating point properties:
local and global error, finiteness *)

From vcfloat Require Import FPLang FPLangOpt RAux Rounding Reify Float_notations Automate.
Require Import IntervalFlocq3.Tactic.
Import Binary.
Import List ListNotations.
Set Bullet Behavior "Strict Subproofs".

Require Import lf_harm_float lf_harm_real real_lemmas lf_harm_real_theorems lf_harm_lemmas.

Open Scope R_scope.

Section WITHNANS.

Context {NANS: Nans}.

Lemma prove_roundoff_bound_q:
  forall pq : state,
  prove_roundoff_bound leapfrog_bmap (leapfrog_vmap pq) q' 
    (2.704*(1/10^6)).
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
   (1.436*(1/10^6)).
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
        <= (2.704*(1/10^6))
.
Proof.
intros.
apply (prove_roundoff_bound_q pq H).
Qed.

Lemma prove_roundoff_bound_p_implies:
  forall pq : state,
  boundsmap_denote leapfrog_bmap (leapfrog_vmap pq)-> 
  Rabs (FT2R (fval (env_ (leapfrog_vmap pq)) p') - rval (env_ (leapfrog_vmap pq)) p') <= (1.436*(1/10^6))
.
Proof.
intros.
apply (prove_roundoff_bound_p pq H).
Qed.

Definition local_round_off :=  ∥(1.436*(1/10^6), 2.704*(1/10^6))∥.

Lemma itern_implies_bmd_aux1:
  forall pnf qnf : ftype Tsingle,
  forall pnr qnr : R,
  forall n,
  (n <= 100)%nat -> 
  ∥ Rprod_minus (pnr, qnr) (FT2R_prod (pnf, qnf)) ∥ <=  local_round_off * error_sum (1 + h) n 
  /\ ∥(pnr,qnr) ∥ <= 21.697 -> 
  Rabs (FT2R pnf)  <= 22 /\ Rabs ( FT2R qnf) <= 22.
Proof.
intros ? ? ? ? ? BNDn H. destruct H as (A & B).
assert (HYP1: ∥ Rprod_minus (pnr, qnr) (FT2R_prod (pnf, qnf)) ∥ <=
(local_round_off) * error_sum (1 + h) 100).
+ eapply Rle_trans.
2 :  { 
apply Rmult_le_compat_l; try (apply Rnorm_pos). 
eapply error_sum_le_trans. apply BNDn. unfold h; nra.
} apply A.
+ clear A. 
(* use the fact that (error_sum (1 + h) 200 = 15032.068779571218 *)
assert ( HYP2 :∥ Rprod_minus (pnr, qnr) (FT2R_prod (pnf, qnf)) ∥ <=
    local_round_off * 15033).
eapply Rle_trans.
apply HYP1.
apply Rmult_le_compat_l; try (apply Rnorm_pos).
apply error_sum_bound; try lia.
clear HYP1. 
assert (HYP3: (∥ (FT2R_prod (pnf, qnf))∥ - ∥ (pnr, qnr) ∥) <=local_round_off * 15033 ).
eapply Rle_trans.
apply Rprod_triang_inv.
rewrite Rprod_minus_comm.
apply HYP2.
apply Rle_minus_l_2 in HYP3. 
assert (HYP4: ∥ FT2R_prod (pnf, qnf) ∥ <= 21.697 + local_round_off * 15033).
eapply Rle_trans.
2: {apply Rplus_le_compat_r. apply B.
} apply HYP3. clear HYP2.
generalize HYP4.
match goal with |-context[Rprod_norm ?A <= ?a]=>
  interval_intro a upper; intros ?HYP; clear HYP;
match goal with [H: a <= ?B |- _] =>
set (valB:= B)
end
end. 
unfold Rprod_norm in HYP4. 
unfold FT2R_prod, fst ,snd in HYP4.
assert (HYP5: sqrt (FT2R pnf  ^ 2 + FT2R qnf ^ 2) <= sqrt (valB^2) ).
eapply Rle_trans. apply  HYP4.
rewrite sqrt_pow2; try nra; try (unfold valB; nra); apply H.
apply sqrt_le_0 in HYP5; try nra.
split. 
++ assert (FT2R pnf ^ 2 <= valB ^ 2) by nra.
apply sqrt_le in H0.
rewrite sqrt_pow2 in H0.
all: (try interval).
++ assert (FT2R qnf ^ 2 <= valB ^ 2) by nra.
apply sqrt_le in H0.
rewrite sqrt_pow2 in H0.
all: (try interval).
Qed.



Lemma itern_implies_bmd:
  forall p q: ftype Tsingle,
  forall n,
  (S n <= 100)%nat -> 
  boundsmap_denote leapfrog_bmap 
    (leapfrog_vmap (iternF (p,q) n)) ->
  ∥(iternR (FT2R p, FT2R q) h (S n)) - FT2R_prod (iternF (p,q)  (S n)) ∥ <= 
  local_round_off * error_sum (1 + h) (S n)  /\
∥ (iternR (FT2R p, FT2R q) h  (S n))∥ <= 21.697 ->
   boundsmap_denote leapfrog_bmap (leapfrog_vmap (iternF (p,q) (S n))).
Proof. 
intros ? ? ? BNDn BMD NORM.
pose proof (itern_implies_bmd_aux (p,q) n BMD) as HFIN.
pose proof (itern_implies_bmd_aux1) as HBND.
unfold boundsmap_denote in *.
intros.
specialize (BMD i).
pose proof bmd_Sn_bnds_le i as ABSBND.
destruct (Maps.PTree.get i leapfrog_bmap).
-
specialize (ABSBND v eq_refl).
destruct v. 
simpl in ABSBND.
rewrite step_iternF in *.
destruct ((iternF (p, q) n)).
set (f1 := (fst (leapfrog_stepF (f, f0)))) in *.
set (f2:=(snd (leapfrog_stepF (f, f0)))) in *.
pose proof  (Maps.PTree.elements_correct
   (leapfrog_vmap (f1,f2)) i) as COR. 
pose proof  (Maps.PTree.elements_correct
   (leapfrog_vmap (f,f0)) i) as COR2.
pose proof (leapfrog_vmap_shape (f1,f2) (f,f0) i) as EX.
simpl in BMD. 
destruct (Maps.PTree.get i (leapfrog_vmap (f1,f2)));
destruct (Maps.PTree.get i (leapfrog_vmap (f,f0)));
try contradiction.
+
specialize (COR2 s0 eq_refl).
inversion COR2; clear COR2.
*
inversion H; subst; clear H.
simpl in BMD.
specialize (COR s eq_refl).
inversion COR; clear COR.
--
inversion H; subst; clear H.
split; try ( apply BMD).
split. simpl. apply BMD.
split. apply HFIN.
destruct ((iternR (FT2R p, FT2R q) h (S n))).
specialize (HBND f1 f2 r r0 (S n) BNDn NORM). 
destruct ABSBND.
subst.
unfold projT2. 
destruct HBND.
apply Rabs_le_inv; auto.
--
simpl in H; destruct H; try contradiction.
inversion H; subst; clear H.
*
simpl in H; destruct H; try contradiction.
inversion H; subst; clear H.
simpl in BMD.
specialize (COR s eq_refl).
inversion COR; clear COR.
--
inversion H; subst; clear H.
--
inversion H; subst; clear H.
++ 
inversion H0; subst; clear H0.
split; try ( apply BMD).
split. simpl. apply BMD.
split. apply HFIN.
destruct ((iternR (FT2R p, FT2R q) h (S n))).
specialize (HBND f1 f2 r r0 (S n) BNDn NORM). 
destruct ABSBND.
subst.
unfold projT2. 
destruct HBND.
apply Rabs_le_inv; auto.
++ 
inversion H0; subst; clear H0.
+
specialize (EX s eq_refl).
destruct EX as (A & B & C); discriminate.
-
rewrite step_iternF in *.
destruct ((iternF (p, q) n)).
destruct (Maps.PTree.get i (leapfrog_vmap (f,f0))) eqn:?H; try contradiction.
destruct (Maps.PTree.get i (leapfrog_vmap (leapfrog_stepF (f, f0)))) eqn:?H; auto.
apply leapfrog_vmap_shape with (pq1 := (f,f0)) in H0.
destruct H0 as [? [? ?]].
congruence.
Qed.

Lemma roundoff_norm_bound:
  forall pq : state,
  boundsmap_denote leapfrog_bmap (leapfrog_vmap pq)-> 
  let (pnf, qnf) := FT2R_prod (fval (env_ (leapfrog_vmap pq)) p', fval (env_ (leapfrog_vmap pq)) q') in 
  let (pnr, qnr) := (rval (env_ (leapfrog_vmap pq)) p', rval (env_ (leapfrog_vmap pq)) q') in
  ∥ (pnf, qnf) - (pnr, qnr)∥ <= local_round_off.
Proof.
intros.
unfold Rprod_minus, FT2R_prod, Rprod_norm, fst, snd.
rewrite <- pow2_abs.
rewrite Rplus_comm.
rewrite <- pow2_abs.
pose proof prove_roundoff_bound_p_implies pq H.
pose proof prove_roundoff_bound_q_implies pq H.
apply sqrt_le_1_alt.
eapply Rle_trans.
apply Rplus_le_compat_r.
apply pow_incr.
split; try (apply Rabs_pos).
apply H1.
eapply Rle_trans. 
apply Rplus_le_compat_l.
apply pow_incr.
split; try (apply Rabs_pos).
apply H0.
unfold fst, snd.
nra.
Qed.

Lemma global_error : 
  boundsmap_denote leapfrog_bmap 
  (leapfrog_vmap pq_init) ->
  forall n : nat, 
  (n <= 100)%nat -> 
  let vmap_n := (leapfrog_vmap (iternF pq_init n)) in
  let c:= local_round_off in 
  let (pr0, qr0) := (FT2R p_init, FT2R q_init) in
  boundsmap_denote leapfrog_bmap vmap_n /\
  ∥(iternR (pr0, qr0) h n) - FT2R_prod (iternF pq_init n) ∥ 
     <= c * error_sum (1 + h) n.
  Proof.
intros.
induction n.
- unfold Rprod_minus. simpl. repeat rewrite Rminus_eq_0.
unfold Rprod_norm, fst, snd. repeat rewrite pow_ne_zero; try lia.
rewrite Rplus_0_r. rewrite sqrt_0.
split.  try nra.
  + apply H.
  + nra. 
- 
match goal with |- context [?A /\ ?B] =>
  assert B; try split; auto
end.
+ 
destruct IHn as (IHbmd & IHnorm); try lia.
rewrite step_iternF; rewrite step_iternR.
assert (BNDn: (n<= 100)%nat) by lia.
pose proof iternR_bound n BNDn.
destruct (iternR (FT2R p_init, FT2R q_init) h n) as (pnr, qnr). 
destruct (iternF pq_init n) as (pnf, qnf).
match goal with |- context[∥?a - ?b∥ <=  _] =>
  let c := (constr:(leapfrog_stepR (FT2R_prod (pnf, qnf)) h)) in
  replace (∥a - b∥) with (∥ Rprod_plus (a - c) (c - b) ∥)
end.
eapply Rle_trans.
apply Rprod_triang_ineq.
rewrite leapfrog_minus_args.
eapply Rle_trans.
apply Rplus_le_compat_l.

assert (∥ Rprod_minus (pnr, qnr) (FT2R_prod (pnf, qnf)) ∥ <=
     local_round_off * error_sum (1 + h) n /\ ∥ (pnr, qnr) ∥ <= 21.697).
split; auto.
pose proof (roundoff_norm_bound (pnf,qnf) IHbmd) as BND.
rewrite reflect_reify_pq in BND.
rewrite rval_correct_pq in BND.
destruct (FT2R_prod (leapfrog_stepF (pnf, qnf))). 
rewrite Rprod_minus_comm in BND. 
apply BND.  
destruct (Rprod_minus (pnr, qnr) (FT2R_prod (pnf, qnf))).
assert (0 < ω*h <= 2) as Hh by (unfold h,ω; nra).
pose proof (method_norm_bounded r r0 h Hh) as BND.
eapply Rle_trans.
apply Rplus_le_compat_r.
apply BND. 
eapply Rle_trans.
apply Rplus_le_compat_r.
apply Rmult_le_compat_l; try (unfold h; nra).
apply IHnorm. 
fold c.
replace ((1 + h) * (c * error_sum (1 + h) n) + c)
with
(c * ((1 + h) * (error_sum (1 + h) n) + 1)) by nra.
rewrite <- error_sum_aux2; unfold c; nra.
symmetry. apply Rprod_norm_plus_minus_eq.
+ destruct IHn as (IHbmd & IHnorm); try lia.
apply itern_implies_bmd; try lia; auto; split; auto.
pose proof iternR_bound (S n); auto.
Qed. 

Theorem total_error: 
  forall pt qt: R -> R,
  forall n : nat, 
  (n <= 100)%nat ->
  let t0 := 0 in
  let tn := t0 + INR n * h in
  pt t0 = FT2R p_init ->
  qt t0 = FT2R q_init ->
  Harmonic_oscillator_system pt qt ω t0 ->
  let c:= local_round_off / h in 
  ∥ (pt tn, qt tn) - (FT2R_prod (iternF (p_init,q_init) n)) ∥ 
     <=  (h^2  + c) * ((1 + h) ^ n - 1) .
Proof.
assert (BMD: boundsmap_denote leapfrog_bmap (leapfrog_vmap pq_init)) by
apply bmd_init.
intros ? ? ? ? ? ? Hp Hq Hsys ; simpl.
match goal with |- context[?A <= ?B] =>
replace A with
  (∥ ((pt (t0 + INR n * h)%R, qt (t0 + INR n * h)%R) - (iternR (FT2R p_init, FT2R q_init) h n)) +
((iternR (FT2R p_init, FT2R q_init) h n) - (FT2R_prod (iternF (p_init,q_init) n))) ∥)
end.
assert (HSY: Harmonic_oscillator_system pt qt 1 t0) by auto.
unfold Harmonic_oscillator_system in Hsys.
rename Hsys into C.
eapply Rle_trans.
apply Rprod_triang_ineq.
eapply Rle_trans.
apply Rplus_le_compat_l.
apply global_error; auto.
eapply Rle_trans.
apply Rplus_le_compat_r.
rewrite <- Hp, <- Hq in *.
eapply global_truncation_error_aux; try unfold h,ω; try nra; auto.
apply Rle_refl.
assert (hlow: 0 < h) by (unfold h; nra).
 pose proof error_sum_GS n h hlow as GS.
rewrite GS.
apply Req_le.
replace ((∥ (/ 7662000, / 4068166) ∥) * (((1 + h) ^ n - 1) / h))
with 
((∥ (/ 7662000, / 4068166) ∥) / h  * ((1 + h) ^ n - 1) ).
replace (∥ (pt t0, qt t0) ∥) with 1.
field_simplify; nra.
symmetry.
rewrite Hp, Hq.
apply init_norm_eq.
field_simplify; repeat nra.
field_simplify.
symmetry; apply Rprod_norm_plus_minus_eq.
Qed. 

Definition accurate_harmonic_oscillator_100 (pq: state) :=
  forall pt qt: R -> R,
  let t0 := 0 in
  let n := 100%nat in 
  let tn := t0 + INR n * h in
  pt t0 = FT2R p_init ->
  qt t0 = FT2R q_init ->
  Harmonic_oscillator_system pt qt ω t0 ->
  ∥ (pt tn, qt tn) - (FT2R (fst pq), FT2R (snd pq)) ∥ <= 0.0223.

Corollary yes_accurate_harmonic_oscillator_100: 
          accurate_harmonic_oscillator_100 (iternF (p_init,q_init) 100).
Proof.
intros.
red; intros.
eapply Rle_trans.
apply total_error; auto.
clear.
unfold local_round_off, Rprod_norm, fst,snd,h.
interval.
Qed.

Theorem yes_iternF_is_finite: iternF_is_finite.
Proof.
red; intros.
pose proof global_error bmd_init n H.
destruct H0 as (A & _).
apply boundsmap_denote_e in A.
simpl Maps.PTree.elements in A.
unfold list_forall in A.
destruct A as (A & B).
destruct A as (V1 & V2 & V3 & V4 & V5).  
  inversion V3; subst.
apply Classical_Prop.EqdepTheory.inj_pair2 in H1; subst. 
destruct B as (U1 & U2 & U3 & U4 & U5). 
inversion U3; subst.
apply Classical_Prop.EqdepTheory.inj_pair2 in H1; subst.
auto. 
Qed.

End WITHNANS.