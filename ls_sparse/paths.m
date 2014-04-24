function paths
  ifpath('get_blob_mask', [pwd '/util']);
  ifpath('mean_speed', [pwd '/speeds']);
end

function ifpath(fn,p)
  if ~exist(fn), addpath(p); end
end
