function run
  iterations = 200;

  paths;
  clf; colormap gray;

  %- load image for truck, let user select point
  load('images/truck');

  %disp('draw initial segmentation: left-click marks boundary points, right-click finishes');
  %mask = get_blob_mask(img);
  
  %- speed functional
  %h = mean_speed();
  %h = mean_var_speed();
  %h = georgiou_speed();
  %h = bhattacharyya_speed();
  h = threshold_speed();
  
  %- initialize
  [phi C] = mask2phi(mask);
  h.init(img, phi, C); % initialize statistics
  
  %- curve evolution
  [phi_ C_] = ls_sparse(phi, C, h, iterations);

  %- display results
  clf; imagesc(img); axis image off;
  hold on;
  contour(phi,  [0 0], 'r', 'LineWidth', 2); % initial
  contour(phi_, [0 0], 'b', 'LineWidth', 2); % final
  hold off;

end
