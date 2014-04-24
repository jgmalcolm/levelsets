function h = mean_speed
  % Chan, Vese "Active contours without edges" TIP 2001

  % required
  h.init_iteration = @init_iteration;
  h.move_in = @move_in;
  h.move_out = @move_out;
  % extensions
  h.init = @init;
  
  s = [];  % dummy for lexical scoping

  function init(img, phi, C)  % manually call this to set up statistics
    s.img = img;
    %-- inside
    idx = find(phi <= 0);
    s.in.area = numel(idx);
    s.in.mean = mean(img(idx));
    %-- outside
    idx = find(0 < phi);
    s.out.area = numel(idx);
    s.out.mean = mean(img(idx));
  end

  function F = init_iteration(phi, C)  % called at the beginning of each new iteration
    u = s.in.mean;
    v = s.out.mean;
    I = double(s.img(C));
    F = (I-v).^2 - (I-u).^2; % Chan-Vese
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
  f_unpacked = from.mean * from.area;
  t_unpacked = to.mean * to.area;
  % add
  to.area = to.area + numel(p);
  to.mean = (t_unpacked + sum(img(p)))/to.area;
  % remove
  from.area = from.area - numel(p);
  from.mean = (f_unpacked - sum(img(p)))/from.area;
end
