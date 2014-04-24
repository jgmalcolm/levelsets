function h = mean_var_speed
  % Rousson, Deriche "A variational framework for active and adaptive
  % segmentation of vector valued images" WMVC 2002.

  % required
  h.init_iteration = @init_iteration;
  h.move_in = @move_in;
  h.move_out = @move_out;
  % extensions
  h.init = @init;
  
  s = [];  % dummy for lexical scoping

  % called at the beginning of each new image
  function init(img, phi, C)
    s.img = double(img);
    %-- inside
    idx = find(phi <= 0);
    s.in.area = numel(idx);
    s.in.mean = mean(s.img(idx));
    s.in.var = var(s.img(idx), 1);
    %-- outside
    idx = find(phi > 0);
    s.out.area = numel(idx);
    s.out.mean = mean(s.img(idx));
    s.out.var = var(s.img(idx), 1);
  end


  % called at the beginning of each new iteration
  function S = init_iteration(phi, C)
    u = s.in.mean;
    uu = s.in.var + eps;

    v = s.out.mean;
    vv = s.out.var + eps;
    I = double(s.img(C));
    
    S = log(vv/uu) - (I-u).^2/uu + (I-v).^2/vv;
  end
  
  % called after each iteration to update statistics
  function move_in(p)
    [s.out s.in] = update(s.out, s.in, s.img, p); % update means, counts
  end
  function move_out(p)
    [s.in s.out] = update(s.in, s.out, s.img, p); % update means, counts
  end
end






function [from to] = update(from, to, img, p)
  n = numel(p);

  %-- from
  Exx = ((from.var + from.mean^2)*from.area - sum(img(p).^2)) / (from.area-n);
  from.mean = (from.mean*from.area - sum(img(p))) / (from.area-n);
  from.var = Exx - from.mean^2;
  from.area = from.area - n;

  %-- to
  Exx = ((to.var + to.mean^2)*to.area + sum(img(p).^2)) / (to.area+n);
  to.mean = (to.mean*to.area + sum(img(p))) / (to.area+n);
  to.var = Exx - to.mean^2;
  to.area = to.area + n;
  
end
