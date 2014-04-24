function [phi C] = ls_discrete(phi, C, h, iter)
  % shift operations
  shiftD = @(M) M([1 1:end-1],:);
  shiftL = @(M) M(:,[2:end end]);
  shiftR = @(M) M(:,[1 1:end-1]);
  shiftU = @(M) M([2:end end],:);

  for i = 1:iter
    %- dilate
    F = h.init_iteration(phi, C);
    F(F < 0) = 0; % only allow dilation
    [phi C] = evolve(phi, C, F, h);
    %- contract
    F = h.init_iteration(phi, C);
    F(F > 0) = 0; % only allow contraction
    [phi C] = evolve(phi, C, F, h);
  end

  % move curve C according to corresponding forces F
  function [phi C] = evolve(phi, C, F, h)
    %- update phi
    phi(C(F > 0)) = -1;
    phi(C(F < 0)) =  1;

    %- off-contour points with neighbors of opposite sign become interface
    Nd = shiftD(phi); Nu = shiftU(phi); Nr = shiftR(phi); Nl = shiftL(phi);
    is_opposite = Nu.*phi < 0 | Nd.*phi < 0 | Nl.*phi < 0 | Nr.*phi < 0;
    is_opposite(C) = 0; % ignore contour points
    is_opposite = find(is_opposite);
    phi(is_opposite) = 0;  % mark those as interface

    %- maintain minimal interface
    Nd = shiftD(phi); Nu = shiftU(phi); Nr = shiftR(phi); Nl = shiftL(phi);
    all_pos = phi == 0 & (Nu >= 0 & Nd >= 0 & Nl >= 0 & Nr >= 0);
    all_neg = phi == 0 & (Nu <= 0 & Nd <= 0 & Nl <= 0 & Nr <= 0);
    phi(all_pos) =  1;
    phi(all_neg) = -1;

    %- move in and move out
    h.move_in(is_opposite);
    h.move_out([C(F < 0); find(all_pos)]);

    C = find(phi == 0); % new curve
  end

end
