function run
  iterations = 10;

  paths;
  clf; colormap gray;

  %- load image and mask for truck
  load('images/truck');
  
  %- let user select mask
%   img = imread('images/truck.png');
%   disp('draw initial segmentation: left-click marks boundary points, right-click finishes');
%   mask = get_blob_mask(img);

  %- speed functional
  %h = mean_speed();
  %h = georgiou_speed();
  %h = bhattacharyya_speed();
  %h = threshold_speed();
  h = mean_var_speed();
  
  %- initialize
  [phi C] = mask2phi(mask);
  h.init(img, phi, C); % initialize statistics
  
  %- curve evolution
  [phi_ C_] = ls_discrete(phi, C, h, iterations);

  %- display results
  imagesc(img); axis image off;
  hold on;
  contour(phi_, [0 0], 'b', 'LineWidth', 3); % final
  contour(phi,  [0 0], 'r', 'LineWidth', 3); % initial
  hold off;

end
