/-
Copyright (c) 2015 Ulrik Buchholtz. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ulrik Buchholtz, Floris van Doorn

Connectedness of types and functions
-/
import types.trunc types.arrow_2 types.lift

open eq is_trunc is_equiv nat equiv trunc function fiber funext pi pointed

definition is_conn [reducible] (n : ℕ₋₂) (A : Type) : Type :=
is_contr (trunc n A)

definition is_conn_fun [reducible] (n : ℕ₋₂) {A B : Type} (f : A → B) : Type :=
Πb : B, is_conn n (fiber f b)

definition is_conn_inf [reducible] (A : Type) : Type := Πn, is_conn n A
definition is_conn_fun_inf [reducible] {A B : Type} (f : A → B) : Type := Πn, is_conn_fun n f

namespace is_conn

  definition is_conn_equiv_closed (n : ℕ₋₂) {A B : Type}
    : A ≃ B → is_conn n A → is_conn n B :=
  begin
    intros H C,
    exact is_contr_equiv_closed (trunc_equiv_trunc n H) C,
  end

  definition is_conn_equiv_closed_rev (n : ℕ₋₂) {A B : Type} (f : A ≃ B) (H : is_conn n B) :
    is_conn n A :=
  is_conn_equiv_closed n f⁻¹ᵉ _

  definition is_conn_of_eq {n m : ℕ₋₂} (p : n = m) {A : Type} (H : is_conn n A) : is_conn m A :=
  transport (λk, is_conn k A) p H

  theorem is_conn_of_le (A : Type) {n k : ℕ₋₂} (H : n ≤ k) [is_conn k A] : is_conn n A :=
  is_contr_equiv_closed (trunc_trunc_equiv_left _ H) _

  theorem is_conn_fun_of_le {A B : Type} (f : A → B) {n k : ℕ₋₂} (H : n ≤ k)
    [is_conn_fun k f] : is_conn_fun n f :=
  λb, is_conn_of_le _ H

  definition is_conn_of_is_conn_succ (n : ℕ₋₂) (A : Type) [is_conn (n.+1) A] : is_conn n A :=
  is_trunc_trunc_of_le A -2 (trunc_index.self_le_succ n)

  namespace is_conn_fun
  section
    parameters (n : ℕ₋₂) {A B : Type} {h : A → B}
               (H : is_conn_fun n h) (P : B → Type) [Πb, is_trunc n (P b)]

    private definition rec.helper : (Πa : A, P (h a)) → Πb : B, trunc n (fiber h b) → P b :=
    λt b, trunc.rec (λx, point_eq x ▸ t (point x))

    private definition rec.g : (Πa : A, P (h a)) → (Πb : B, P b) :=
    λt b, rec.helper t b (@center (trunc n (fiber h b)) (H b))

    -- induction principle for n-connected maps (Lemma 7.5.7)
    protected definition rec : is_equiv (λs : Πb : B, P b, λa : A, s (h a)) :=
    adjointify (λs a, s (h a)) rec.g
    begin
      intro t, apply eq_of_homotopy, intro a, unfold rec.g, unfold rec.helper,
      rewrite [@center_eq _ (H (h a)) (tr (fiber.mk a idp))],
    end
    begin
      intro k, apply eq_of_homotopy, intro b, unfold rec.g,
      generalize (@center _ (H b)), apply trunc.rec, apply fiber.rec,
      intros a p, induction p, reflexivity
    end

    protected definition elim : (Πa : A, P (h a)) → (Πb : B, P b) :=
    @is_equiv.inv _ _ (λs a, s (h a)) rec

    protected definition elim_β : Πf : (Πa : A, P (h a)), Πa : A, elim f (h a) = f a :=
    λf, apd10 (@is_equiv.right_inv _ _ (λs a, s (h a)) rec f)

  end

  section
    parameters (n k : ℕ₋₂) {A B : Type} {f : A → B}
               (H : is_conn_fun n f) (P : B → Type) [HP : Πb, is_trunc (n +2+ k) (P b)]

    include H HP
    -- Lemma 8.6.1
    proposition elim_general : is_trunc_fun k (pi_functor_left f P) :=
    begin
      revert P HP,
      induction k with k IH: intro P HP t,
      { apply is_contr_fiber_of_is_equiv, apply is_conn_fun.rec, exact H, exact HP},
      { apply is_trunc_succ_intro,
        intros x y, cases x with g p, cases y with h q,
        have e : fiber (λr : g ~ h, (λa, r (f a))) (apd10 (p ⬝ q⁻¹))
                 ≃ (fiber.mk g p = fiber.mk h q
                     :> fiber (λs : (Πb, P b), (λa, s (f a))) t),
        begin
          apply equiv.trans !fiber.sigma_char,
          have e' : Πr : g ~ h,
                 ((λa, r (f a)) = apd10 (p ⬝ q⁻¹))
               ≃ (ap (λv, (λa, v (f a))) (eq_of_homotopy r) ⬝ q = p),
          begin
            intro r,
            refine equiv.trans _ (eq_con_inv_equiv_con_eq q p
                                   (ap (λv a, v (f a)) (eq_of_homotopy r))),
            rewrite [-(ap (λv a, v (f a)) (apd10_eq_of_homotopy_fn r))],
            rewrite [-(apd10_ap_precompose_dependent f (eq_of_homotopy r))],
            apply equiv.symm,
            apply eq_equiv_fn_eq_of_is_equiv (@apd10 A (λa, P (f a)) (λa, g (f a)) (λa, h (f a)))
          end,
          apply equiv.trans (sigma.sigma_equiv_sigma_right e'), clear e',
          apply equiv.trans (equiv.symm (sigma.sigma_equiv_sigma_left
                                           !eq_equiv_homotopy)),
          apply equiv.symm, apply equiv.trans !fiber_eq_equiv,
          apply sigma.sigma_equiv_sigma_right, intro r,
          apply eq_equiv_eq_symm
        end,
        apply @is_trunc_equiv_closed _ _ k e, clear e,
        apply IH (λb : B, (g b = h b)) (λb, @is_trunc_eq (P b) (n +2+ k) (HP b) (g b) (h b)) }
    end

  end

  section
    universe variables u v
    parameters (n : ℕ₋₂) {A : Type.{u}} {B : Type.{v}} {h : A → B}
    parameter sec : ΠP : B → trunctype.{max u v} n,
                    is_retraction (λs : (Πb : B, P b), λ a, s (h a))

    private definition s := sec (λb, trunctype.mk' n (trunc n (fiber h b)))

    include sec

    -- the other half of Lemma 7.5.7
    definition intro : is_conn_fun n h :=
    begin
      intro b,
      apply is_contr.mk (@is_retraction.sect _ _ _ s (λa, tr (fiber.mk a idp)) b),
      esimp, apply trunc.rec, apply fiber.rec, intros a p,
      apply transport
               (λz : (Σy, h a = y), @sect _ _ _ s (λa, tr (mk a idp)) (sigma.pr1 z) =
                                    tr (fiber.mk a (sigma.pr2 z)))
               (@center_eq _ (is_contr_sigma_eq (h a)) (sigma.mk b p)),
      exact apd10 (@right_inverse _ _ _ s (λa, tr (fiber.mk a idp))) a
    end
  end
  end is_conn_fun

  -- Connectedness is related to maps to and from the unit type, first to
  section
    parameters (n : ℕ₋₂) (A : Type)

    definition is_conn_of_map_to_unit
      : is_conn_fun n (const A unit.star) → is_conn n A :=
    begin
      intro H, unfold is_conn_fun at H,
      exact is_conn_equiv_closed n (fiber.fiber_star_equiv A) _,
    end

    definition is_conn_fun_to_unit_of_is_conn [H : is_conn n A] :
      is_conn_fun n (const A unit.star) :=
    begin
      intro u, induction u,
      exact is_conn_equiv_closed n (fiber.fiber_star_equiv A)⁻¹ᵉ _,
    end

    -- now maps from unit
    definition is_conn_of_map_from_unit (a₀ : A) (H : is_conn_fun n (const unit a₀))
      : is_conn n .+1 A :=
    is_contr.mk (tr a₀)
    begin
      apply trunc.rec, intro a,
      exact trunc.elim (λz : fiber (const unit a₀) a, ap tr (point_eq z))
                            (@center _ (H a))
    end

    definition is_conn_fun_from_unit (a₀ : A) [H : is_conn n .+1 A]
      : is_conn_fun n (const unit a₀) :=
    begin
      intro a,
      apply is_conn_equiv_closed n (equiv.symm (fiber_const_equiv A a₀ a)),
      apply is_contr_equiv_closed (tr_eq_tr_equiv n a₀ a) _,
    end

  end

  -- as special case we get elimination principles for pointed connected types
  namespace is_conn
    open pointed unit
    section
      parameters (n : ℕ₋₂) {A : Type*}
                 [H : is_conn n .+1 A] (P : A → Type) [Πa, is_trunc n (P a)]

      include H
      protected definition rec : is_equiv (λs : Πa : A, P a, s (Point A)) :=
      @is_equiv_compose
        (Πa : A, P a) (unit → P (Point A)) (P (Point A))
        (λf, f unit.star) (λs x, s (Point A))
        (is_conn_fun.rec n (is_conn_fun_from_unit n A (Point A)) P)
        (to_is_equiv (arrow_unit_left (P (Point A))))

      protected definition elim : P (Point A) → (Πa : A, P a) :=
      @is_equiv.inv _ _ (λs, s (Point A)) rec

      protected definition elim_β (p : P (Point A)) : elim p (Point A) = p :=
      @is_equiv.right_inv _ _ (λs, s (Point A)) rec p
    end

    section
      parameters (n k : ℕ₋₂) {A : Type*}
                 [H : is_conn n .+1 A] (P : A → Type) [Πa, is_trunc (n +2+ k) (P a)]

      include H
      proposition elim_general (p : P (Point A))
        : is_trunc k (fiber (λs : (Πa : A, P a), s (Point A)) p) :=
      @is_trunc_equiv_closed
        (fiber (λs x, s (Point A)) (λx, p))
        (fiber (λs, s (Point A)) p)
        k
        (equiv.symm (fiber.equiv_postcompose _ (arrow_unit_left (P (Point A))) _))
        (is_conn_fun.elim_general n k (is_conn_fun_from_unit n A (Point A)) P (λx, p))
    end
  end is_conn

  -- Lemma 7.5.2
  definition minus_one_conn_of_surjective {A B : Type} (f : A → B)
    : is_surjective f → is_conn_fun -1 f :=
  begin
    intro H, intro b,
    exact is_contr_of_inhabited_prop (H b) _,
  end

  definition is_surjection_of_minus_one_conn {A B : Type} (f : A → B)
    : is_conn_fun -1 f → is_surjective f :=
  begin
    intro H, intro b,
    exact @center (∥fiber f b∥) (H b),
  end

  definition merely_of_minus_one_conn {A : Type} : is_conn -1 A → ∥A∥ :=
  λH, @center (∥A∥) H

  definition minus_one_conn_of_merely {A : Type} : ∥A∥ → is_conn -1 A :=
  λx, is_contr_of_inhabited_prop x _

  section
    open arrow

    variables {f g : arrow}

    -- Lemma 7.5.4
    definition retract_of_conn_is_conn [instance] (r : arrow_hom f g) [H : is_retraction r]
      (n : ℕ₋₂) [K : is_conn_fun n f] : is_conn_fun n g :=
    begin
      intro b, unfold is_conn,
      apply is_contr_retract (trunc_functor n (retraction_on_fiber r b)),
      exact K (on_cod (arrow.is_retraction.sect r) b)
    end

  end

  -- Corollary 7.5.5
  definition is_conn_homotopy (n : ℕ₋₂) {A B : Type} {f g : A → B}
    (p : f ~ g) (H : is_conn_fun n f) : is_conn_fun n g :=
  @retract_of_conn_is_conn _ _
    (arrow.arrow_hom_of_homotopy p) (arrow.is_retraction_arrow_hom_of_homotopy p) n H

  /- introduction rules for connectedness -/
  -- all types are -2-connected
  definition is_conn_minus_two (A : Type) : is_conn -2 A :=
  _

  -- merely inhabited types are -1-connected
  definition is_conn_minus_one (A : Type) (a : ∥ A ∥) : is_conn -1 A :=
  is_contr.mk a (is_prop.elim _)

  definition is_conn_minus_one_pointed [instance] (A : Type*) : is_conn -1 A :=
  is_conn_minus_one A (tr pt)

  definition is_conn_succ_intro {n : ℕ₋₂} {A : Type} (a : trunc (n.+1) A)
    (H2 : Π(a a' : A), is_conn n (a = a')) : is_conn (n.+1) A :=
  begin
    refine is_contr_of_inhabited_prop _ _,
    { exact a },
    { apply is_trunc_succ_intro,
      refine trunc.rec _, intro a, refine trunc.rec _, intro a',
      exact is_contr_equiv_closed !tr_eq_tr_equiv⁻¹ᵉ _ }
  end

  definition is_conn_zero {A : Type} (a₀ : trunc 0 A) (p : Πa a' : A, ∥ a = a' ∥) : is_conn 0 A :=
  is_conn_succ_intro a₀ (λa a', is_conn_minus_one _ (p a a'))

  definition is_conn_zero_pointed {A : Type*} (p : Πa a' : A, ∥ a = a' ∥) : is_conn 0 A :=
  is_conn_zero (tr pt) p

  definition is_conn_zero_pointed' {A : Type*} (p : Πa : A, ∥ a = pt ∥) : is_conn 0 A :=
  is_conn_zero_pointed (λa a', tconcat (p a) (tinverse (p a')))

  /- connectedness of certain types -/
  definition is_conn_trunc [instance] (A : Type) (n k : ℕ₋₂) [H : is_conn n A]
    : is_conn n (trunc k A) :=
  is_contr_equiv_closed !trunc_trunc_equiv_trunc_trunc _

  definition is_conn_eq [instance] (n : ℕ₋₂) {A : Type} (a a' : A) [is_conn (n.+1) A] :
    is_conn n (a = a') :=
  is_contr_equiv_closed !tr_eq_tr_equiv _

  definition is_conn_loop [instance] (n : ℕ₋₂) (A : Type*) [is_conn (n.+1) A] : is_conn n (Ω A) :=
  !is_conn_eq

  open pointed
  definition is_conn_ptrunc [instance] (A : Type*) (n k : ℕ₋₂) [H : is_conn n A]
    : is_conn n (ptrunc k A) :=
  is_conn_trunc A n k

  definition is_conn_pathover (n : ℕ₋₂) {A : Type} {B : A → Type} {a a' : A} (p : a = a') (b : B a)
    (b' : B a') [is_conn (n.+1) (B a')] : is_conn n (b =[p] b') :=
  is_conn_equiv_closed_rev n !pathover_equiv_tr_eq _

  open sigma
  lemma is_conn_sigma [instance] {A : Type} (B : A → Type) (n : ℕ₋₂)
    [HA : is_conn n A] [HB : Πa, is_conn n (B a)] : is_conn n (Σa, B a) :=
  begin
    revert A B HA HB, induction n with n IH: intro A B HA HB,
    { apply is_conn_minus_two },
    apply is_conn_succ_intro,
    { induction center (trunc (n.+1) A) with a, induction center (trunc (n.+1) (B a)) with b,
      exact tr ⟨a, b⟩ },
    intro a a', refine is_conn_equiv_closed_rev n !sigma_eq_equiv _,
    apply IH, apply is_conn_eq, intro p, apply is_conn_pathover
    /- an alternative proof of the successor case -/
    -- induction center (trunc (n.+1) A) with a₀,
    -- induction center (trunc (n.+1) (B a₀)) with b₀,
    -- apply is_contr.mk (tr ⟨a₀, b₀⟩),
    -- intro ab, induction ab with ab, induction ab with a b,
    -- induction tr_eq_tr_equiv n a₀ a !is_prop.elim with p, induction p,
    -- induction tr_eq_tr_equiv n b₀ b !is_prop.elim with q, induction q,
    -- reflexivity
  end

  lemma is_conn_prod [instance] (A B : Type) (n : ℕ₋₂) [is_conn n A] [is_conn n B] :
    is_conn n (A × B) :=
  is_conn_equiv_closed n !sigma.equiv_prod _

  lemma is_conn_fun_of_is_conn {A B : Type} (n : ℕ₋₂) (f : A → B)
    [HA : is_conn n A] [HB : is_conn (n.+1) B] : is_conn_fun n f :=
  λb, is_conn_equiv_closed_rev n !fiber.sigma_char _

  definition is_conn_fiber_of_is_conn (n : ℕ₋₂) {A B : Type} (f : A → B) (b : B) [is_conn n A]
    [is_conn (n.+1) B] : is_conn n (fiber f b) :=
  is_conn_fun_of_is_conn n f b

  lemma is_conn_pfiber_of_is_conn {A B : Type*} (n : ℕ₋₂) (f : A →* B)
    [HA : is_conn n A] [HB : is_conn (n.+1) B] : is_conn n (pfiber f) :=
  is_conn_fun_of_is_conn n f pt

  definition is_conn_of_is_contr (k : ℕ₋₂) (A : Type) [is_contr A] : is_conn k A := _

  definition is_conn_succ_of_is_conn_loop {n : ℕ₋₂} {A : Type*}
    (H : is_conn 0 A) (H2 : is_conn n (Ω A)) : is_conn (n.+1) A :=
  begin
    apply is_conn_succ_intro, exact tr pt,
    intros a a',
    induction merely_of_minus_one_conn (is_conn_eq -1 a a') with p, induction p,
    induction merely_of_minus_one_conn (is_conn_eq -1 pt a) with p, induction p,
    exact H2
  end

  /- connected functions -/
  definition is_conn_fun_of_is_equiv (k : ℕ₋₂) {A B : Type} (f : A → B) [is_equiv f] :
    is_conn_fun k f :=
  _

  definition is_conn_fun_id (k : ℕ₋₂) (A : Type) : is_conn_fun k (@id A) :=
  λa, _

  definition is_conn_fun_compose (k : ℕ₋₂) {A B C : Type} {g : B → C} {f : A → B}
    (Hg : is_conn_fun k g) (Hf : is_conn_fun k f) : is_conn_fun k (g ∘ f) :=
  λc, is_conn_equiv_closed_rev k (fiber_compose_equiv g f c) _

  -- Lemma 7.5.14
  theorem is_equiv_trunc_functor_of_is_conn_fun [instance] {A B : Type} (n : ℕ₋₂) (f : A → B)
    [H : is_conn_fun n f] : is_equiv (trunc_functor n f) :=
  begin
    fapply adjointify,
    { intro b, induction b with b, exact trunc_functor n point (center (trunc n (fiber f b)))},
    { intro b, induction b with b, esimp, generalize center (trunc n (fiber f b)), intro v,
      induction v with v, induction v with a p, esimp, exact ap tr p},
    { intro a, induction a with a, esimp, rewrite [center_eq (tr (fiber.mk a idp))]}
  end

  definition trunc_equiv_trunc_of_is_conn_fun {A B : Type} (n : ℕ₋₂) (f : A → B)
    [H : is_conn_fun n f] : trunc n A ≃ trunc n B :=
  equiv.mk (trunc_functor n f) (is_equiv_trunc_functor_of_is_conn_fun n f)

  definition ptrunc_pequiv_ptrunc_of_is_conn_fun {A B : Type*} (n : ℕ₋₂) (f : A →* B)
    [H : is_conn_fun n f] : ptrunc n A ≃* ptrunc n B :=
  pequiv_of_pmap (ptrunc_functor n f) (is_equiv_trunc_functor_of_is_conn_fun n f)

  definition is_conn_fun_trunc_functor_of_le {n k : ℕ₋₂} {A B : Type} (f : A → B) (H : k ≤ n)
    [H2 : is_conn_fun k f] : is_conn_fun k (trunc_functor n f) :=
  begin
    apply is_conn_fun.intro,
    intro P, have Πb, is_trunc n (P b), from (λb, is_trunc_of_le _ H _),
    fconstructor,
    { intro f' b,
      induction b with b,
      refine is_conn_fun.elim k H2 _ _ b, intro a, exact f' (tr a)},
    { intro f', apply eq_of_homotopy, intro a,
      induction a with a, esimp, rewrite [is_conn_fun.elim_β]}
  end

  definition is_conn_fun_trunc_functor_of_ge {n k : ℕ₋₂} {A B : Type} (f : A → B) (H : n ≤ k)
    [H2 : is_conn_fun k f] : is_conn_fun k (trunc_functor n f) :=
  begin
    apply is_conn_fun_of_is_equiv,
    exact is_equiv_trunc_functor_of_le f H _
  end

  -- Exercise 7.18
  definition is_conn_fun_trunc_functor {n k : ℕ₋₂} {A B : Type} (f : A → B)
    [H2 : is_conn_fun k f] : is_conn_fun k (trunc_functor n f) :=
  begin
    eapply algebra.le_by_cases k n: intro H,
    { exact is_conn_fun_trunc_functor_of_le f H},
    { exact is_conn_fun_trunc_functor_of_ge f H}
  end

  open lift
  definition is_conn_fun_lift_functor (n : ℕ₋₂) {A B : Type} (f : A → B) [is_conn_fun n f] :
    is_conn_fun n (lift_functor f) :=
  begin
    intro b, cases b with b,
    exact is_contr_equiv_closed_rev (trunc_equiv_trunc _ !fiber_lift_functor) _
  end

  open trunc_index
  definition is_conn_fun_inf.mk_nat {A B : Type} {f : A → B} (H : Π(n : ℕ), is_conn_fun n f)
    : is_conn_fun_inf f :=
  begin
    intro n,
    cases n with n, { exact _},
    cases n with n, { have -1 ≤ of_nat 0, from dec_star, apply is_conn_fun_of_le f this},
    rewrite -of_nat_add_two, exact _
  end

  definition is_conn_inf.mk_nat {A : Type} (H : Π(n : ℕ), is_conn n A) : is_conn_inf A :=
  begin
    intro n,
    cases n with n, { exact _},
    cases n with n, { have -1 ≤ of_nat 0, from dec_star, apply is_conn_of_le A this},
    rewrite -of_nat_add_two, exact _
  end

  definition is_conn_fun_trunc_elim_of_le {n k : ℕ₋₂} {A B : Type} [is_trunc n B] (f : A → B)
    (H : k ≤ n) [H2 : is_conn_fun k f] : is_conn_fun k (trunc.elim f : trunc n A → B) :=
  begin
    apply is_conn_fun.intro,
    intro P, have Πb, is_trunc n (P b), from (λb, is_trunc_of_le _ H _),
    fconstructor,
    { intro f' b,
      refine is_conn_fun.elim k H2 _ _ b, intro a, exact f' (tr a) },
    { intro f', apply eq_of_homotopy, intro a,
      induction a with a, esimp, rewrite [is_conn_fun.elim_β] }
  end

  definition is_conn_fun_trunc_elim_of_ge {n k : ℕ₋₂} {A B : Type} [is_trunc n B] (f : A → B)
    (H : n ≤ k) [H2 : is_conn_fun k f] : is_conn_fun k (trunc.elim f : trunc n A → B) :=
  begin
   apply is_conn_fun_of_is_equiv,
   have H3 : is_equiv (trunc_functor k f), from !is_equiv_trunc_functor_of_is_conn_fun,
   have H4 : is_equiv (trunc_functor n f), from is_equiv_trunc_functor_of_le _ H _,
   apply is_equiv_of_equiv_of_homotopy (equiv.mk (trunc_functor n f) _ ⬝e !trunc_equiv),
   intro x, induction x, reflexivity
  end

  definition is_conn_fun_trunc_elim {n k : ℕ₋₂} {A B : Type} [is_trunc n B] (f : A → B)
    [H2 : is_conn_fun k f] : is_conn_fun k (trunc.elim f : trunc n A → B) :=
  begin
    eapply algebra.le_by_cases k n: intro H,
    { exact is_conn_fun_trunc_elim_of_le f H },
    { exact is_conn_fun_trunc_elim_of_ge f H }
  end

  lemma is_conn_fun_tr (n : ℕ₋₂) (A : Type) : is_conn_fun n (tr : A → trunc n A) :=
  begin
    apply is_conn_fun.intro,
    intro P,
    fconstructor,
    { intro f' b, induction b with a, exact f' a },
    { intro f', reflexivity }
  end

  definition is_contr_of_is_conn_of_is_trunc {n : ℕ₋₂} {A : Type} (H : is_trunc n A)
    (K : is_conn n A) : is_contr A :=
  is_contr_equiv_closed (trunc_equiv n A) _

  definition is_trunc_succ_succ_of_is_trunc_loop (n : ℕ₋₂) (A : Type*) (H : is_trunc (n.+1) (Ω A))
    (H2 : is_conn 0 A) : is_trunc (n.+2) A :=
  begin
    apply is_trunc_succ_of_is_trunc_loop, apply minus_one_le_succ,
    refine is_conn.elim -1 _ _, exact H
  end

  lemma is_trunc_of_is_trunc_loopn (m n : ℕ) (A : Type*) (H : is_trunc n (Ω[m] A))
    (H2 : is_conn (m.-1) A) : is_trunc (m + n) A :=
  begin
    revert A H H2; induction m with m IH: intro A H H2,
    { rewrite [nat.zero_add], exact H },
    rewrite [succ_add],
    apply is_trunc_succ_succ_of_is_trunc_loop,
    { apply IH,
      { exact is_trunc_equiv_closed _ !loopn_succ_in _ },
      apply is_conn_loop },
    exact is_conn_of_le _ (zero_le_of_nat m)
  end

  lemma is_trunc_of_is_set_loopn (m : ℕ) (A : Type*) (H : is_set (Ω[m] A))
    (H2 : is_conn (m.-1) A) : is_trunc m A :=
  is_trunc_of_is_trunc_loopn m 0 A H H2

end is_conn

/-
  (bundled) connected types, possibly also truncated or with a point
  The notation is n-Type*[k] for k-connected n-truncated pointed types, and you can remove
  `n-`, `[k]` or `*` in any combination to remove some conditions
-/

structure conntype (n : ℕ₋₂) : Type :=
  (carrier : Type)
  (struct : is_conn n carrier)

notation `Type[`:95  n:0 `]`:0 := conntype n

attribute conntype.carrier [coercion]
attribute conntype.struct [instance] [priority 1300]

section
  universe variable u
  structure pconntype (n : ℕ₋₂) extends conntype.{u} n, pType.{u}

  notation `Type*[`:95  n:0 `]`:0 := pconntype n

  /-
    There are multiple coercions from pconntype to Type. Type class inference doesn't recognize
    that all of them are definitionally equal (for performance reasons). One instance is
    automatically generated, and we manually add the missing instances.
  -/

  definition is_conn_pconntype [instance] {n : ℕ₋₂} (X : Type*[n]) : is_conn n X :=
  conntype.struct X

  structure truncconntype (n k : ℕ₋₂) extends trunctype.{u} n,
                                              conntype.{u} k renaming struct→conn_struct

  notation n `-Type[`:95  k:0 `]`:0 := truncconntype n k

  definition is_conn_truncconntype [instance] {n k : ℕ₋₂} (X : n-Type[k]) :
    is_conn k (truncconntype._trans_of_to_trunctype X) :=
  conntype.struct X

  definition is_trunc_truncconntype [instance] {n k : ℕ₋₂} (X : n-Type[k]) : is_trunc n X :=
  trunctype.struct X

  structure ptruncconntype (n k : ℕ₋₂) extends ptrunctype.{u} n,
                                               pconntype.{u} k renaming struct→conn_struct

  notation n `-Type*[`:95  k:0 `]`:0 := ptruncconntype n k

  attribute ptruncconntype._trans_of_to_pconntype ptruncconntype._trans_of_to_ptrunctype
            ptruncconntype._trans_of_to_pconntype_1 ptruncconntype._trans_of_to_ptrunctype_1
            ptruncconntype._trans_of_to_pconntype_2 ptruncconntype._trans_of_to_ptrunctype_2
            ptruncconntype.to_pconntype ptruncconntype.to_ptrunctype
            truncconntype._trans_of_to_conntype truncconntype._trans_of_to_trunctype
            truncconntype.to_conntype truncconntype.to_trunctype [unfold 3]
  attribute pconntype._trans_of_to_conntype pconntype._trans_of_to_pType
            pconntype.to_pType pconntype.to_conntype [unfold 2]

  definition is_conn_ptruncconntype [instance] {n k : ℕ₋₂} (X : n-Type*[k]) :
    is_conn k (ptruncconntype._trans_of_to_ptrunctype X) :=
  conntype.struct X

  definition is_trunc_ptruncconntype [instance] {n k : ℕ₋₂} (X : n-Type*[k]) :
    is_trunc n (ptruncconntype._trans_of_to_pconntype X) :=
  trunctype.struct X
end

namespace is_conn

open sigma sigma.ops prod prod.ops

definition pconntype.sigma_char [constructor] (k : ℕ₋₂) :
  Type*[k] ≃ Σ(X : Type*), is_conn k X :=
equiv.MK (λX, ⟨pconntype.to_pType X, _⟩)
         (λX, pconntype.mk (carrier X.1) X.2 pt)
         begin intro X, induction X with X HX, induction X, reflexivity end
         begin intro X, induction X, reflexivity end

definition is_embedding_pconntype_to_pType (k : ℕ₋₂) : is_embedding (@pconntype.to_pType k) :=
begin
  intro X Y, fapply is_equiv_of_equiv_of_homotopy,
  { exact eq_equiv_fn_eq (pconntype.sigma_char k) _ _ ⬝e subtype_eq_equiv _ _ },
  intro p, induction p, reflexivity
end

definition pconntype_eq_equiv {k : ℕ₋₂} (X Y : Type*[k]) : (X = Y) ≃ (X ≃* Y) :=
equiv.mk _ (is_embedding_pconntype_to_pType k X Y) ⬝e pType_eq_equiv X Y

definition pconntype_eq {k : ℕ₋₂} {X Y : Type*[k]} (e : X ≃* Y) : X = Y :=
(pconntype_eq_equiv X Y)⁻¹ᵉ e

definition ptruncconntype.sigma_char [constructor] (n k : ℕ₋₂) :
  n-Type*[k] ≃ Σ(X : Type*), is_trunc n X × is_conn k X :=
equiv.MK (λX, ⟨ptruncconntype._trans_of_to_pconntype_1 X, (_, _)⟩)
         (λX, ptruncconntype.mk (carrier X.1) X.2.1 pt X.2.2)
         begin intro X, induction X with X HX, induction HX, induction X, reflexivity end
         begin intro X, induction X, reflexivity end

definition ptruncconntype.sigma_char_pconntype [constructor] (n k : ℕ₋₂) :
  n-Type*[k] ≃ Σ(X : Type*[k]), is_trunc n X :=
equiv.MK (λX, ⟨ptruncconntype.to_pconntype X, _⟩)
         (λX, ptruncconntype.mk (pconntype._trans_of_to_pType X.1) X.2 pt _)
         begin intro X, induction X with X HX, induction HX, induction X, reflexivity end
         begin intro X, induction X, reflexivity end

definition is_embedding_ptruncconntype_to_pconntype (n k : ℕ₋₂) :
  is_embedding (@ptruncconntype.to_pconntype n k) :=
begin
  intro X Y, fapply is_equiv_of_equiv_of_homotopy,
  { exact eq_equiv_fn_eq (ptruncconntype.sigma_char_pconntype n k) _ _ ⬝e subtype_eq_equiv _ _ },
  intro p, induction p, reflexivity
end

definition ptruncconntype_eq_equiv {n k : ℕ₋₂} (X Y : n-Type*[k]) : (X = Y) ≃ (X ≃* Y) :=
equiv.mk _ (is_embedding_ptruncconntype_to_pconntype n k X Y) ⬝e pconntype_eq_equiv X Y

definition ptruncconntype_eq {n k : ℕ₋₂} {X Y : n-Type*[k]} (e : X ≃* Y) : X = Y :=
(ptruncconntype_eq_equiv X Y)⁻¹ᵉ e

definition ptruncconntype_functor [constructor] {n n' k k' : ℕ₋₂} (p : n = n') (q : k = k')
  (X : n-Type*[k]) : n'-Type*[k'] :=
ptruncconntype.mk X (is_trunc_of_eq p _) pt (is_conn_of_eq q _)

definition ptruncconntype_equiv [constructor] {n n' k k' : ℕ₋₂} (p : n = n') (q : k = k') :
  n-Type*[k] ≃ n'-Type*[k'] :=
equiv.MK (ptruncconntype_functor p q) (ptruncconntype_functor p⁻¹ q⁻¹)
         (λX, ptruncconntype_eq pequiv.rfl) (λX, ptruncconntype_eq pequiv.rfl)


/- the k-connected cover of X, the fiber of the map X → ∥X∥ₖ. -/
open trunc_index

definition connect (k : ℕ) (X : Type*) : Type* :=
pfiber (ptr k X)

definition is_conn_connect (k : ℕ) (X : Type*) : is_conn k (connect k X) :=
is_conn_fun_tr k X (tr pt)

definition connconnect [constructor] (k : ℕ) (X : Type*) : Type*[k]  :=
pconntype.mk (connect k X) (is_conn_connect k X) pt

definition connect_intro [constructor] {k : ℕ} {X : Type*} {Y : Type*} (H : is_conn k X)
  (f : X →* Y) : X →* connect k Y :=
pmap.mk (λx, fiber.mk (f x) (is_conn.elim (k.-1) _ (ap tr (respect_pt f)) x))
  begin
    fapply fiber_eq, exact respect_pt f, apply is_conn.elim_β
  end

definition ppoint_connect_intro [constructor] {k : ℕ} {X : Type*} {Y : Type*} (H : is_conn k X)
  (f : X →* Y) : ppoint (ptr k Y) ∘* connect_intro H f ~* f :=
begin
  induction f with f f₀, induction Y with Y y₀, esimp at (f,f₀), induction f₀,
  fapply phomotopy.mk,
  { intro x, reflexivity },
  { symmetry, esimp, apply point_fiber_eq }
end

definition connect_intro_ppoint [constructor] {k : ℕ} {X : Type*} {Y : Type*} (H : is_conn k X)
  (f : X →* connect k Y) : connect_intro H (ppoint (ptr k Y) ∘* f) ~* f :=
begin
  cases f with f f₀,
  fapply phomotopy.mk,
  { intro x, fapply fiber_eq, reflexivity,
    refine @is_conn.elim (k.-1) _ _ _ (λx', !is_trunc_eq) _ x,
    refine !is_conn.elim_β ⬝ _,
    refine _ ⬝ !idp_con⁻¹,
    symmetry, refine _ ⬝ !con_idp, exact fiber_eq_pr2 f₀ },
  { esimp, refine whisker_left _ !fiber_eq_eta ⬝ !fiber_eq_con ⬝ apd011 fiber_eq !idp_con _, esimp,
    apply eq_pathover_constant_left,
    refine whisker_right _ (whisker_right _ (whisker_right _ !is_conn.elim_β)) ⬝pv _,
    esimp [connect], refine _ ⬝vp !con_idp,
    apply move_bot_of_left, refine !idp_con ⬝ !con_idp⁻¹ ⬝ph _,
    refine !con.assoc ⬝ !con.assoc ⬝pv _, apply whisker_tl,
    note r := eq_bot_of_square (transpose (whisker_left_idp_square (fiber_eq_pr2 f₀))⁻¹ᵛ),
    refine !con.assoc⁻¹ ⬝ whisker_right _ r⁻¹ ⬝pv _, clear r,
    apply move_top_of_left,
    refine whisker_right_idp (ap_con tr idp (ap point f₀))⁻¹ᵖ ⬝pv _,
    exact (ap_con_idp_left tr (ap point f₀))⁻¹ʰ }
end

definition connect_intro_equiv [constructor] {k : ℕ} {X : Type*} (Y : Type*) (H : is_conn k X) :
  (X →* connect k Y) ≃ (X →* Y) :=
begin
  fapply equiv.MK,
  { intro f, exact ppoint (ptr k Y) ∘*  f },
  { intro g, exact connect_intro H g },
  { intro g, apply eq_of_phomotopy, exact ppoint_connect_intro H g },
  { intro f, apply eq_of_phomotopy, exact connect_intro_ppoint H f }
end

definition connect_intro_pequiv [constructor] {k : ℕ} {X : Type*} (Y : Type*) (H : is_conn k X) :
  ppmap X (connect k Y) ≃* ppmap X Y :=
pequiv_of_equiv (connect_intro_equiv Y H) (eq_of_phomotopy !pcompose_pconst)

definition connect_pequiv {k : ℕ} {X : Type*} (H : is_conn k X) : connect k X ≃* X :=
@pfiber_pequiv_of_is_contr _ _ (ptr k X) H

definition loop_connect (k : ℕ) (X : Type*) : Ω (connect (k+1) X) ≃* connect k (Ω X) :=
loop_pfiber (ptr (k+1) X) ⬝e*
pfiber_pequiv_of_square pequiv.rfl (loop_ptrunc_pequiv k X)
  (phomotopy_of_phomotopy_pinv_left (ap1_ptr k X))

definition loopn_connect (k : ℕ) (X : Type*) : Ω[k+1] (connect k X) ≃* Ω[k+1] X :=
loopn_pfiber (k+1) (ptr k X) ⬝e*
@pfiber_pequiv_of_is_contr _ _ _ (@is_contr_loop_of_is_trunc (k+1) _ !is_trunc_trunc)

definition is_conn_of_is_conn_succ_nat (n : ℕ) (A : Type) [is_conn (n+1) A] : is_conn n A :=
is_conn_of_is_conn_succ n A

definition connect_functor (k : ℕ) {X Y : Type*} (f : X →* Y) : connect k X →* connect k Y :=
pfiber_functor f (ptrunc_functor k f) (ptr_natural k f)⁻¹*

definition connect_intro_pequiv_natural {k : ℕ} {X X' : Type*} {Y Y' : Type*} (f : X' →* X)
  (g : Y →* Y') (H : is_conn k X) (H' : is_conn k X') :
  psquare (connect_intro_pequiv Y H) (connect_intro_pequiv Y' H')
          (ppcompose_left (connect_functor k g) ∘* ppcompose_right f)
          (ppcompose_left g ∘* ppcompose_right f) :=
begin
  refine _ ⬝v* _, exact connect_intro_pequiv Y H',
  { fapply phomotopy.mk,
    { intro h, apply eq_of_phomotopy, apply passoc },
    { xrewrite [▸*, pcompose_right_eq_of_phomotopy, pcompose_left_eq_of_phomotopy,
        -+eq_of_phomotopy_trans],
      apply ap eq_of_phomotopy, apply passoc_pconst_middle }},
  { fapply phomotopy.mk,
    { intro h, apply eq_of_phomotopy,
      refine !passoc⁻¹* ⬝* pwhisker_right h (ppoint_natural _ _ _) ⬝* !passoc },
    { xrewrite [▸*, +pcompose_left_eq_of_phomotopy, -+eq_of_phomotopy_trans],
      apply ap eq_of_phomotopy,
      refine !trans_assoc ⬝ idp ◾** !passoc_pconst_right ⬝ _,
      refine !trans_assoc ⬝ idp ◾** !pcompose_pconst_phomotopy ⬝ _,
      apply symm_trans_eq_of_eq_trans, symmetry, apply passoc_pconst_right }}
end

end is_conn
