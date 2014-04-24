function K = kappa(phi, p)
  % shift operations
  shiftD = @(M) M([1 1:end-1],:);
  shiftL = @(M) M(:,[2:end end]);
  shiftR = @(M) M(:,[1 1:end-1]);
  shiftU = @(M) M([2:end end],:);
  Dx  = @(M) (shiftL(M) - shiftR(M))/2;
  Dy  = @(M) (shiftU(M) - shiftD(M))/2;
  Dxx = @(M) (shiftL(M) - 2*M + shiftR(M));
  Dyy = @(M) (shiftU(M) - 2*M + shiftD(M));
  Dxy = @(M) (shiftU(M) - shiftD(M) + shiftL(M) - shiftR(M))/4;
  
  % derivatives
  dx  = Dx(phi);    dx  = dx(p);
  dy  = Dy(phi);    dy  = dy(p);
  dx2 = dx.^2;
  dy2 = dy.^2;
  dxx = Dxx(phi);   dxx = dxx(p);
  dyy = Dyy(phi);   dyy = dyy(p);
  dxy = Dxy(phi);   dxy = dxy(p);

  K = (dx2.*dyy + dy2.*dxx - 2*dx.*dy.*dxy)./(dx2 + dy2 + eps);
end
