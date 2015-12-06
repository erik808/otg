function [F, V] = eigfreq(cipherFile, plainFile, repeatLength, reuseExisting)
% Correlate the eigenvector against a frequency vector for known plaintext

if nargin < 4
   reuseExisting = true; % by default, re-use existing files
end

% Generate adjacency matrix and map from the cipher
adjFile = sprintf(".adj_%s", cipherFile);
mapFile1 = sprintf(".map1_%s", cipherFile);
pairgraphCommand = sprintf("../pairgraph/pairgraph %s %d %s %s", 
			   cipherFile, repeatLength, adjFile, mapFile1);

if ~reuseExisting || ~exist(adjFile) || ~exist(mapFile1)
   disp("calling")
  system(pairgraphCommand);
end

% Generate substitution matrix
substitutionFile = sprintf(".subsmat_%s", cipherFile);
mapFile2 = sprintf(".map2_%s", cipherFile);
substitutionCommand = sprintf("../substitution_matrix/substitution_matrix %s %s %s %s", 
			      cipherFile, plainFile, substitutionFile, mapFile2);

if ~reuseExisting || ~exist(adjFile) || ~exist(mapFile1)
   disp("calling")
  system(substitutionCommand);
end

% Compute principal eigenvector for the matrix
A = sparse(load(adjFile));
[V, ~] = eigs(A, 1);
V = abs(V) ./ max(abs(V));

% Letter-frequency in English
freq = load('letter_freq_en.mat');
freq = freq.freq;

% Load substitution matrix
S = load(substitutionFile);

% Multiply with frequency-distribution
F = S * freq;

% Show trend
n = 20;
x = linspace(0, max(F), n);
mu = zeros(1, n-1);
sig = zeros(1, n-1);
for i = 1:n-1
    select = V(F > x(i) & F < x(i+1));
    if isempty(select)
       continue
    end
    mu(i) = mean(select);
    sig(i) = std(select);
end

x = x(1:end-1) + (x(2) - x(1))/2;

plot(F, V, '.');
hold on;
plot(x, mu, x, mu + sig, x, mu - sig, 'r.-');
hold off
xlim([0, max(F) * 1.1])
ylim([0, 1.1])
xlabel('F')
ylabel('v')



