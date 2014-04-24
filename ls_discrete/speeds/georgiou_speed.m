function h = georgiou_speed
  % Sandhu et al. "A New Distribution Metric for Image Segmentation" SPIE
  % Medical Imaging 2008.

  % required
  h.init_iteration = @init_iteration;
  h.move_in = @move_in;
  h.move_out = @move_out;
  % extensions
  h.init = @init;
  
  s = [];  % dummy for lexical scoping

  % manually call this to set up statistics
  function init(img, phi, C)
    s.img = img;
    %-- inside
    idx = find(phi <= 0);
    s.in.area = numel(idx);
    s.in.hist = imhist(img(idx));
    %-- outside
    idx = find(0 < phi);
    s.out.area = numel(idx);
    s.out.hist = imhist(img(idx));
  end
  

  % called at the beginning of each new iteration
  function S = init_iteration(phi, C)
    Ap = s.in.area;
    Aq = s.out.area;
    p = s.in.hist  / Ap + eps;
    q = s.out.hist / Aq + eps;
    
    Z = (1:256)'; % vertical since p,q vertical
    lg = log( p ./ q );
    A = Z .* (lg - sum(lg));
    
    lookup = 2*(1/Ap + 1/Aq)*sum(A) - 2*A.*(1./(p*Ap) + 1./(q*Aq));
    S = lookup(s.img(C) + 1);
  end
  
  % called after each iteration to update statistics
  function move_in(p)
    [s.out s.in] = update(s.out, s.in, s.img, p);
  end
  function move_out(p)
    [s.in s.out] = update(s.in, s.out, s.img, p);
  end
end



function [from to] = update(from, to, img, p)
  h = imhist(img(p));
  % add
  to.area = to.area + numel(p);
  to.hist = to.hist + h;
  % remove
  from.area = from.area - numel(p);
  from.hist = from.hist - h;
end
