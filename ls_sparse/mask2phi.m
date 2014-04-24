function [phi C] = mask2phi(mask)
% MASK2PHI Generate phi/C from mask.
%  mask -- true if inside, false if outside
% Note, (phi >= 0) considered inside, so interface considered inside.
%
% >> [phi C] = mask2phi(mask);

  % define matrix shifts
  shiftU = @(M) M([2:end end],:,:);
  shiftD = @(M) M([1 1:end-1],:,:);
  shiftL = @(M) M(:,[2:end end],:);
  shiftR = @(M) M(:,[1 1:end-1],:);
  if ndims(mask) == 3
    shiftF = @(M) M(:,:,[2:end end]);
    shiftB = @(M) M(:,:,[1 1:end-1]);
  else
    [shiftF shiftB] = deal( @(M) 0 );
  end

  %- 1. determine inside and outside
  phi = 2*mask - 1;
  
  %- 2. determine zero interface
  % determine if neighbor of opposite sign
  Nu = shiftD(phi) == -1; Nd = shiftU(phi) == -1;
  Nl = shiftR(phi) == -1; Nr = shiftL(phi) == -1;
  Nf = shiftF(phi) == -1; Nb = shiftB(phi) == -1;
  % determine outside points with neighbors inside
  is_near = phi == 1 & (Nu | Nd | Nl | Nr | Nf | Nb);
  % mark as zero level set
  phi(is_near) = 0;

  %- 3. ensure minimal interface
  Nu = shiftD(phi); Nd = shiftU(phi);
  Nl = shiftR(phi); Nr = shiftL(phi);
  all_pos = phi == 0 & (Nu >= 0 & Nd >= 0 & Nl >= 0 & Nr >= 0 & Nf >= 0 & Nb >= 0);
  all_neg = phi == 0 & (Nu <= 0 & Nd <= 0 & Nl <= 0 & Nr <= 0 & Nf <= 0 & Nb <= 0);
  phi(all_pos) =  1;
  phi(all_neg) = -1;
  
  %- 4. finalize
  C = find(phi == 0);
end
