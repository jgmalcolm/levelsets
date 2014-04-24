function h = mean_speed
  % Chan, Vese "Active contours without edges" TIP 2001

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
    s.in.mean = mean(s.img(idx));
    %-- outside
    idx = find(phi < 0);
    s.out.area = numel(idx);
    s.out.mean = mean(s.img(idx));
  end
  

  % called at the beginning of each new iteration
  function F = init_iteration(phi, C)
    if ndims(phi) == 3
      imagesc(s.img(:,:,50)); axis image off;
      hold on; contour(phi(:,:,50), [0 0], 'b', 'LineWidth', 2); hold off; drawnow
    else
      imagesc(s.img); axis image off;
      hold on; contour(phi, [0 0], 'b', 'LineWidth', 2); hold off; drawnow
    end

    u = s.in.mean;
    v = s.out.mean;
    I = double(s.img(C));

    F = (I-u).^2 - (I-v).^2; % Chan-Vese
    F = F/max(abs(F)) - .8*kappa(phi, C);
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
