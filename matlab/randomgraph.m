function [A1] = randomgraph(size, threshold)
  if nargin < 2
	threshold = 0.999
  end
  A0  = zeros(size);
  A1  = rand(size);
  rng = (A1 > threshold);
  A0(rng) = (A1(rng));
  A1  = sparse(A0);
  A1  = triu(A1) + triu(A1)'; % make symmetric
  A1  = A1 - diag(diag(A1));  % get rid of diagonal

end
