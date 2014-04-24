function [phi L_z] = ls_sparse3(phi, L_z, h, iter)
  % Whitaker "A Level-Set Approach to 3D Reconstruction..." IJCV 1998
  CFL = .4;
  % shift and peek operations
  peekD = @(M,rr,cc,dd) M(safe_sub2ind(size(phi), rr-1, cc,   dd));
  peekU = @(M,rr,cc,dd) M(safe_sub2ind(size(phi), rr+1, cc,   dd));
  peekR = @(M,rr,cc,dd) M(safe_sub2ind(size(phi), rr,   cc-1, dd));
  peekL = @(M,rr,cc,dd) M(safe_sub2ind(size(phi), rr,   cc+1, dd));
  peekF = @(M,rr,cc,dd) M(safe_sub2ind(size(phi), rr,   cc,   dd+1));
  peekB = @(M,rr,cc,dd) M(safe_sub2ind(size(phi), rr,   cc,   dd-1));
  shiftD = @(M) M([1 1:end-1],:,:);
  shiftL = @(M) M(:,[2:end end],:);
  shiftR = @(M) M(:,[1 1:end-1],:);
  shiftU = @(M) M([2:end end],:,:);
  shiftF = @(M) M(:,:,[2:end end]);
  shiftB = @(M) M(:,:,[1 1:end-1]);
  
  %- gather layers
  Nd = shiftD(phi); Nu = shiftU(phi); Nr = shiftR(phi); Nl = shiftL(phi); Nf = shiftF(phi); Nb = shiftB(phi);
  L_i = find(phi < -.5 & (Nu >= -.5 | Nd >= -.5 | Nl >= -.5 | Nr >= -.5 | Nf >= -.5 | Nb >= -.5));
  L_o = find(phi >  .5 & (Nu <=  .5 | Nd <=  .5 | Nl <=  .5 | Nr <=  .5 | Nf <=  .5 | Nb <=  .5));
  %- layer reverse lookup
  L_rev = 2*ones(size(phi), 'int8'); % default: outside
  L_rev(phi < 0) = -2; % inside
  L_rev(L_i) = -1;
  L_rev(L_o) =  1;
  L_rev(L_z) =  0;
  
  for i = 1:iter
    % record sign
    L_z_ = L_z;
    L_z_phi_ = phi(L_z);

    %- 1. update value of zero layer (with uncontrollable force)
    F = h.init_iteration(phi, L_z);
    phi(L_z) = phi(L_z) - CFL*F/max(abs(F)); % control that force

    %- 3. update status of zero layer
    S_i = L_z(phi(L_z) < -.5     );
    S_o = L_z(      .5 < phi(L_z));
    L_z(phi(L_z) < -.5 | .5 < phi(L_z)) = []; % drop
    
    %- 2. update value of nonzero layers
    [rr cc dd] = ind2sub(size(phi), L_i);
    N = [peekR(phi,rr,cc,dd) peekL(phi,rr,cc,dd) ...
         peekU(phi,rr,cc,dd) peekD(phi,rr,cc,dd) ...
         peekF(phi,rr,cc,dd) peekB(phi,rr,cc,dd)];
    phi(L_i) = max(N,[],2) - 1;
    [rr cc dd] = ind2sub(size(phi), L_o);
    N = [peekR(phi,rr,cc,dd) peekL(phi,rr,cc,dd) ...
         peekU(phi,rr,cc,dd) peekD(phi,rr,cc,dd) ...
         peekF(phi,rr,cc,dd) peekB(phi,rr,cc,dd)];
    phi(L_o) = min(N,[],2) + 1;

    %- 4. update status of nonzero layers
    S_zi = L_i(     -.5 <= phi(L_i));
    S_zo = L_o(phi(L_o) <= .5      );
    L_rev(L_i(phi(L_i) < -1.5)) = -2;
    L_rev(L_o(phi(L_o) >  1.5)) =  2;
    L_i(phi(L_i) < -1.5 | -.5 <= phi(L_i)) = [];
    L_o(phi(L_o) <=  .5 | 1.5 <  phi(L_o)) = [];

    %- 5. update reverse lookup
    L_rev(S_i) = -1;
    L_rev(S_o) =  1;
    L_rev([S_zi; S_zo]) = 0;
    
    %- 7. add new neighbors
    Nl = shiftL(L_rev) == 0; Nr = shiftR(L_rev) == 0; Nu = shiftU(L_rev) == 0;
    Nd = shiftD(L_rev) == 0; Nf = shiftF(L_rev) == 0; Nb = shiftB(L_rev) == 0;
    is_near = Nl | Nr | Nu | Nd | Nf | Nb;
    S_oo = find(L_rev ==  2 & is_near);
    S_ii = find(L_rev == -2 & is_near);
    L_o = [L_o; S_o; S_oo];
    L_i = [L_i; S_i; S_ii];
    L_z = [L_z; S_zi; S_zo];
    L_rev(S_ii) = -1;
    L_rev(S_oo) =  1;

    %- 8. update values of new neighbors
    [rr cc dd] = ind2sub(size(phi), S_ii);
    N = [peekR(phi,rr,cc,dd) peekL(phi,rr,cc,dd) ...
         peekU(phi,rr,cc,dd) peekD(phi,rr,cc,dd) ...
         peekF(phi,rr,cc,dd) peekB(phi,rr,cc,dd)];
    phi(S_ii) = max(N,[],2) - 1;
    [rr cc dd] = ind2sub(size(phi), S_oo);
    N = [peekR(phi,rr,cc,dd) peekL(phi,rr,cc,dd) ...
         peekU(phi,rr,cc,dd) peekD(phi,rr,cc,dd) ...
         peekF(phi,rr,cc,dd) peekB(phi,rr,cc,dd)];
    phi(S_oo) = min(N,[],2) + 1;
    
    %- 9. update bookkeeping
    L_z_phi = phi(L_z_);
    idx_out = L_z_(L_z_phi_ > 0  & L_z_phi <= 0);
    idx_in  = L_z_(L_z_phi_ <= 0 & L_z_phi > 0);
    h.move_in(idx_in);
    h.move_out(idx_out);
  end
end



function ind = safe_sub2ind(sz, rr, cc, dd)
  rr(rr < 1) = 1;
  rr(rr > sz(1)) = sz(1);
  cc(cc < 1) = 1;
  cc(cc > sz(2)) = sz(2);
  dd(dd < 1) = 1;
  dd(dd > sz(3)) = sz(3);
  ind = sub2ind(sz, rr, cc, dd);
end
