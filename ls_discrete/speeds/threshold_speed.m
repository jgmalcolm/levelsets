function h = threshold_speed
  % Dambreville et al. "A variational framework combining level-sets and
  % thresholding" BMVC 2007.

  % parameters
  param.eps_2 = 1;

  % required
  h.init_iteration = @init_iteration;
  h.move_in = @move_in;
  h.move_out = @move_out;
  % extensions
  h.init = @init;
  
  s = [];  % dummy for lexical scoping


  function init(img, phi, C)
    s.img = double(img);
    %-- inside
    idx = find(phi <= 0);
    s.in.area = numel(idx);
    s.in.mean = mean(s.img(idx));
    %-- outside
    idx = find(phi > 0);
    s.out.area = numel(idx);
    s.out.mean = mean(s.img(idx));
  end


  % called at the beginning of each new iteration
  function S = init_iteration(phi, C)
    u = s.in.mean;  Ain = s.in.area + eps;
    v = s.out.mean; Aout= s.out.area + eps;
    I = s.img(:);

    sgn = sign(u - v);
    tau = heaviside(sgn*(I - (u + v)/2), param.eps_2);
    H_eps2 = 1-(double(phi(:)) + 1)/2;
    d_eps2 = dirac(sgn*(I - (u+v)/2), param.eps_2);
    beta = sgn * sum(d_eps2 .* (H_eps2 - tau));
    
    S = -2*(H_eps2(C) - tau(C)) - beta*((I(C)-u)/Ain - (I(C)-v)/Aout);
%     S = (I(C)-v).^2 - (I(C)-u).^2; % Chan-Vese
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
  f_unpacked = from.mean * from.area;
  t_unpacked = to.mean * to.area;
  % add
  to.area = to.area + numel(p);
  to.mean = (t_unpacked + sum(img(p)))/to.area;
  % remove
  from.area = from.area - numel(p);
  from.mean = (f_unpacked - sum(img(p)))/from.area;
end



function H = heaviside(x, eps)
  H = zeros(size(x));
  H(eps < x) = 1;
  ind = find(abs(x) < eps);
  x = x(ind);
  H(ind) = (1 + x/eps + sin(pi*x/eps)/pi)/2;
end

function d = dirac(x, eps)
  d = zeros(size(x));
  ind = find(abs(x) < eps);
  x = x(ind);
  d(ind) = (1 + cos(pi*x/eps))/2/eps;
end
