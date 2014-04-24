function K = kappa3(phi, p)
  [rr cc dd] = ind2sub(size(phi), p);

  % shift operations
  shiftD = @(M) M(safe_sub2ind(size(phi), rr-1, cc,   dd));
  shiftU = @(M) M(safe_sub2ind(size(phi), rr+1, cc,   dd));
  shiftR = @(M) M(safe_sub2ind(size(phi), rr,   cc-1, dd));
  shiftL = @(M) M(safe_sub2ind(size(phi), rr,   cc+1, dd));
  shiftF = @(M) M(safe_sub2ind(size(phi), rr,   cc,   dd+1));
  shiftB = @(M) M(safe_sub2ind(size(phi), rr,   cc,   dd-1));

  shiftUL = @(M) M(safe_sub2ind(size(phi), rr-1, cc-1,   dd));
  shiftUR = @(M) M(safe_sub2ind(size(phi), rr-1, cc+1,   dd));
  shiftDL = @(M) M(safe_sub2ind(size(phi), rr+1,   cc-1, dd));
  shiftDR = @(M) M(safe_sub2ind(size(phi), rr+1,   cc+1, dd));

  shiftUF = @(M) M(safe_sub2ind(size(phi), rr-1, cc, dd+1));
  shiftUB = @(M) M(safe_sub2ind(size(phi), rr-1, cc, dd-1));
  shiftDF = @(M) M(safe_sub2ind(size(phi), rr+1, cc, dd+1));
  shiftDB = @(M) M(safe_sub2ind(size(phi), rr+1, cc, dd-1));

  shiftLF = @(M) M(safe_sub2ind(size(phi), rr, cc-1, dd+1));
  shiftLB = @(M) M(safe_sub2ind(size(phi), rr, cc-1, dd-1));
  shiftRF = @(M) M(safe_sub2ind(size(phi), rr, cc+1, dd+1));
  shiftRB = @(M) M(safe_sub2ind(size(phi), rr, cc+1, dd-1));

  % derivative operations
  Dx  = @(M) (shiftL(M) - shiftR(M))/2;
  Dy  = @(M) (shiftU(M) - shiftD(M))/2;
  Dz  = @(M) (shiftF(M) - shiftB(M))/2;
  Dxx = @(M) (shiftL(M) - 2*M(p) + shiftR(M));
  Dyy = @(M) (shiftU(M) - 2*M(p) + shiftD(M));
  Dzz = @(M) (shiftF(M) - 2*M(p) + shiftB(M));

  Dxy = @(M) (shiftUL(M) + shiftDR(M) - shiftUR(M) - shiftDL(M))/4;
  Dxz = @(M) (shiftLF(M) + shiftRB(M) - shiftRF(M) - shiftLB(M))/4;
  Dyz = @(M) (shiftUF(M) + shiftDB(M) - shiftDF(M) - shiftUB(M))/4;
  
  % derivatives
  dx  = Dx(phi);  dy  = Dy(phi);  dz  = Dz(phi);
  dx2 = dx.^2;    dy2 = dy.^2;    dz2 = dz.^2;
  dxx = Dxx(phi); dyy = Dyy(phi); dzz = Dzz(phi);
  dxy = Dxy(phi); dxz = Dxz(phi); dyz = Dyz(phi);

  K = (dxx.*(dy2 + dz2) + dyy.*(dx2 + dz2) + dzz.*(dx2 + dy2) ...
       - 2*dx.*dy.*dxy - 2*dx.*dz.*dxz - 2*dy.*dz.*dyz) ./ ...
      (dx2 + dy2 + dz2 + eps);
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
