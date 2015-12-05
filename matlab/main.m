function [graph, map, V, D] = main(adjfile, mapfile)

  graph = sparse(load(adjfile));
  N = size(graph,1);
  
  A1 = speye(N) + graph;  
  A2 = A1 + (A1^2)/2;
  A3 = A2 + (A1^3)/6;
  A4 = A3 + (A1^4)/24;

  figure(1)
  subplot(2,2,1)
  spy(A1, 'k.');
  subplot(2,2,2)
  spy(A2 + 0.5*graph*graph, 'k.');		   
  subplot(2,2,3)
  spy(A3, 'k.');		   
  subplot(2,2,4)
  spy(A4, 'k.');
  
  [V,D] = eigs(A1,6,'lm');

  map   = importdata(mapfile);

  figure(2)
  % principal eigenvector
  for k = 1:4
	ev = V(:,k);
	subplot(2,2,k)
	plot(map.data, ev, 'k.', map.data, diag(A4)/norm(diag(A4)), 'ro');
  end
end
