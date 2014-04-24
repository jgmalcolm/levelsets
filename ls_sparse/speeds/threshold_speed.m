function h = threshold_speed
  % Dambreville et al. "A variational framework combining level-sets and
  % thresholding" BMVC 2007.

  % parameters
  param.eps_1 = 2;
  param.eps_2 = 200 * param.eps_1;

  % required
  h.init_iteration = @init_iteration;
  h.move_in = @move_in;
  h.move_out = @move_out;
  % extensions
  h.init = @init;
  
  s = [];  % dummy for lexical scoping
  
  E = [];

  function init(img, phi, C)
    s.img = double(img);
    %-- inside
    idx = find(phi >= 0);
    s.in.area = numel(idx);
    s.in.mean = mean(s.img(idx));
    %-- outside
    idx = find(phi < 0);
    s.out.area = numel(idx);
    s.out.mean = mean(s.img(idx));
  end


  function S = init_iteration(phi, C)
    u = s.in.mean;  Au = s.in.area + eps;
    v = s.out.mean; Av = s.out.area + eps;
    I = s.img(:);

    HP = heaviside(phi(:), param.eps_1);
    dP = dirac(phi(:), param.eps_1);
    
    G = (u-v)*(I - (u+v)/2); % from thesis
    HG = heaviside(G, param.eps_2);
    dG = dirac(G, param.eps_2);
    a = sum(dG.*(I - u).*(HP - HG));
    b = sum(dG.*(I - v).*(HP - HG));
    S = (HP(C) - HG(C)) - a*(I(C)-u)/Au - b*(I(C)-v)/Av;

%     G = sign(u-v)*(I - (u+v)/2); % from ICIP
%     HG = heaviside(G, param.eps_2);
%     dG = dirac(G, param.eps_2);
%     beta = sign(u-v)*sum( dG .* (HP - HG) );
%     dTau = (v-I(C))/Av + (I(C)-u)/Au;
%     S = (HP(C) - HG(C)) + beta * dTau;

    S = dP(C).*S - .1*kappa(phi, C);

    subplot(2,1,1); imagesc(s.img); axis image off
    hold on; contour(phi, [0 0], 'b', 'LineWidth', 2); hold off;
    E(end+1) = sum((HP - HG).^2);
    subplot(2,1,2); plot(E);
    drawnow
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
  ind = find(abs(x) <= eps);
  x = x(ind);
  H(ind) = (1 + x/eps + sin(pi*x/eps)/pi)/2;
end

function d = dirac(x, eps)
  d = zeros(size(x));
  ind = find(abs(x) <= eps);
  x = x(ind);
  d(ind) = (1 + cos(pi*x/eps))/2/eps;
end
