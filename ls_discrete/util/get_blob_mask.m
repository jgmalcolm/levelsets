function mask = get_blob_mask(img)
  
  pts = grab_input(img);
  interface = round(init_interface(pts));
  interface = sub2ind(size(img), interface(1,:), interface(2,:));

  % propagate inward from outside
  mask = ones(size(img), 'int8'); % default: object
  [mask(1,:) mask(end,:) mask(:,1) mask(:,end)] = deal(0);
  
  % mark object special
  mask(interface) = -1; % stop value

  % propagate inward till encounter stop values at interface
  for i = 1:numel(img)
    [mask is_unchanged] = propagate(mask);
    if is_unchanged, break, end
  end
  
  % fix up interface
  mask = (mask == 1);
end
  
  
  
  
  
  
  
  
function [mask is_unchanged] = propagate(mask)
  L = shiftR(mask); R = shiftL(mask);
  U = shiftD(mask); D = shiftU(mask);
  
  is_neighboring = (mask==1)&(L==0 | R==0 | U==0 | D==0);
  mask(is_neighboring) = 0;
  
  is_unchanged = all(is_neighboring == false);
end








function interface = init_interface(input)
% INIT_INTERFACE Determine the initial zero-level set points and from those
% construct an initial signed distance function.
%
% INTERFACE = INIT_INTERFACE(INPUT) Uses INPUT as user selected grid points so
% as to not halt for user input thus automating the process.  Proceeds with
% constructing the initial signed distance function.
  
  interface = [];
  input(:,end+1) = input(:,1);  % make pseudo-cyclic, i.e. first item
                                % duplicated at end

  for i = 1:(size(input,2)-1) % last refences first that's copied to end
    interface = [ interface genpts(input(:,i), input(:,i+1)) ];
  end


  function pts = genpts(a, b)
  % GENPTS generates intervening points between a and b
    
    % We want the dimension with largest coordinate difference to be our reference
    % point to control the granularity at which we create the connecting line.
    diffs = b - a;
    max_diff = max(abs(diffs));
    if max_diff == 0, pts = a; return, end

    %-- Calculate slope vector m --%
    m = (b - a)/max_diff;
    
    %-- Generate intervening points --%
    pts = [];
    for t = 0:(max_diff-1)
      p = a + m*t;
      pts = [ pts p ];
    end
  end % genpts

end % init_interface







function pts = grab_input(img)
% GRAB_INPUT Grab the INPUT array for an image
%
% pts = GRAB_INPUT(img)
%
% Example:
%  >> pts = grab_input(imread('blob.png'));

  imagesc(img); axis image off;
  [ xpts ypts ] = getline;
  pts = round([ypts xpts])';

  global INPUT
  if numel(xpts) == 1
    pts = INPUT;
  else
    INPUT = pts;
  end

end
function M = shiftU(M)
  M = M([2:end end],:);
end
function M = shiftR(M)
  M = M(:,[1 1:end-1]);
end
function M = shiftL(M)
  M = M(:,[2:end end]);
end
function M = shiftD(M)
  M = M([1 1:end-1],:);
end
