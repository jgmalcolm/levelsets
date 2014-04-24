function mask = get_rect_mask(img)
  global INPUT
  
  imagesc(img); axis image off;
  r = round(getrect);
  
  if all(r(3:4) == [0 0])
    r = INPUT;
  else
    INPUT = r;
  end
  mask = false(size(img));
  mask(r(2)+(1:r(4)), r(1)+(1:r(3))) = true;
end
