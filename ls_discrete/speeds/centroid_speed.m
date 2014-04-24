function h = centroid_speed
  % required
  h.init_iteration = @init_iteration;
  h.move_in = @move_in;
  h.move_out = @move_out;
  % extensions
  h.init = @init;
  h.postprocess = @postprocess;
  h.set_img = @set_img;
  h.get_state = @get_state;
  
  s = [];  % dummy for lexical scoping

  % manually call this to set up statistics
  function init(img, phi, C)
    %-- outside
    idx = find(0 < phi);
    s.out.area = numel(idx);
    s.out.mean = mean(s.img(idx));
    %-- inside
    idx = find(phi <= 0);
    s.in.area = numel(idx);
    s.in.mean = mean(s.img(idx));
    %-- centroid of inside
    [yy xx] = ind2sub(size(phi), idx);
    s.centroid = [mean(yy) mean(xx)];
  end


  % called at the beginning of each new iteration
  function F = init_iteration(phi, C)
    u = s.in.mean;
    v = s.out.mean;
    I = double(s.img(C));

    F = (I-v).^2 - (I-u).^2; % Chan-Vese
  end
  
  % called after each iteration to update statistics
  function move_in(p)
    [s.out s.in] = update(s.out, s.in, s.img, p); % update means, counts
    %- update centroid
    [yy xx] = ind2sub(size(s.img), single(p));
    s.centroid = (s.centroid*(s.in.area-numel(p)) + sum([yy' xx']))/s.in.area;
  end
  function move_out(p)
    [s.in s.out] = update(s.in, s.out, s.img, p); % update means, counts
    [yy xx] = ind2sub(size(s.img), single(p));
    s.centroid = (s.centroid*(s.in.area+numel(p)) - sum([yy' xx']))/s.in.area;
  end
  
  
  function s_ = get_state
    s_ = s;
  end
  function set_img(img)
    s.img = img;
  end
  function postprocess(phi)
  end
end






function [from to] = update(from, to, img, p) % vectorized
  f_unpacked = from.mean * from.area;
  t_unpacked = to.mean * to.area;
  % add
  to.area = to.area + numel(p);
  to.mean = (t_unpacked + sum(img(p)))/to.area;
  % remove
  from.area = from.area - numel(p);
  from.mean = (f_unpacked - sum(img(p)))/from.area;
end
