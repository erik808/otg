function [graph, map, V, D] = main(adjfile, mapfile)

  graph = sparse(load(adjfile));
  N = size(graph,1);

  A0 = speye(N);
  A1 = speye(N) + graph;
  Ap = A1;
  o  = 2;
  Ao = zeros(N);
  for j = 1:o
	Ao = Ao + 1/factorial(j)*Ap;
	Ap = Ap * graph;
  end
  
  figure(1)
  subplot(2,2,1)
  spy(A1, 'k.');
  subplot(2,2,2)
  spy(Ao, 'k.');
  subplot(2,2,3)

  opts.tol=eps;
  [V,D] = eigs(Ao,6,'lm',opts);

  map   = importdata(mapfile);

  figure(2)
  % principal eigenvector
  ev = V(:,1);
  ev(abs(ev)<1e-3) = 0;
  plot(map.data, abs(ev)/max(abs(ev)), 'k.');
end
