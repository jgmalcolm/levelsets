function h = bhattacharyya_speed
  % Rathi et al. "Seeing the Unseen: Segmenting with Distributions" SIP 2006

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
    idx = find(phi >= 0);
    s.in.area = numel(idx);
    s.in.hist = imhist(img(idx));
    %-- outside
    idx = find(phi < 0);
    s.out.area = numel(idx);
    s.out.hist = imhist(img(idx));
  end
  

  % called at the beginning of each new iteration
  function F = init_iteration(phi, C)
    imagesc(s.img); axis image off
    hold on; contour(phi, [0 0], 'b', 'LineWidth', 2); hold off; drawnow

    Ap = s.in.area;
    Aq = s.out.area;
    p = s.in.hist  / Ap + eps; % leave histograms unsmoothed
    q = s.out.hist / Aq + eps;
    
    B = sum(sqrt(p .* q));
    integral = sqrt(p./q)/Aq - sqrt(q./p)/Ap;

    lookup = -B/2*(1/Ap - 1/Aq) - integral/2;
    F = lookup(s.img(C) + 1);
    
    F = F/max(abs(F)) - .3*kappa(phi, C);
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
  n = numel(p);
  h = imhist(img(p));
  % add
  to.area = to.area + n;
  to.hist = to.hist + h;
  % remove
  from.area = from.area - n;
  from.hist = from.hist - h;
end
