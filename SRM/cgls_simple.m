function [X,rho,eta,F] = cgls_simple(A,b,k,reorth,s)
%CGLS Conjugate gradient algorithm applied implicitly to the normal equations.
%
% [X,rho,eta,F] = cgls(A,b,k,reorth,s)
%
% Performs k steps of the conjugate gradient algorithm applied
% implicitly to the normal equations A'*A*x = A'*b.
%
% The routine returns all k solutions, stored as columns of
% the matrix X.  The corresponding solution and residual norms
% are returned in the vectors eta and rho, respectively.
%
% If the singular values s are also provided, cgls computes the
% filter factors associated with each step and stores them
% columnwise in the matrix F.
%
% Reorthogonalization of the normal equation residual vectors
% A'*(A*X(:,i)-b) is controlled by means of reorth:
%    reorth = 0 : no reorthogonalization (default),
%    reorth = 1 : reorthogonalization by means of MGS.

% References: A. Bjorck, "Numerical Methods for Least Squares Problems",
% SIAM, Philadelphia, 1996.
% C. R. Vogel, "Solving ill-conditioned linear systems using the
% conjugate gradient method", Report, Dept. of Mathematical
% Sciences, Montana State University, 1987.

% Per Christian Hansen, IMM, July 23, 2007.

% The fudge threshold is used to prevent filter factors from exploding.
fudge_thr = 1e-4;

% Initialization.
if (k < 1), error('Number of steps k must be positive'), end
if (nargin==3), reorth = 0; end
[m,n] = size(A); X = zeros(n,k);
eta = zeros(k,1); rho = eta;

% Prepare for CG iteration.
x = zeros(n,1);
d = A'*b;
r = b;
normr2 = d'*d;

% Iterate.
for j=1:k
    
    % Update x and r vectors.
    Ad = A*d; 
    alpha = normr2/(Ad'*Ad);
    x  = x + alpha*d;
    r  = r - alpha*Ad;
    s  = A'*r;
    
    % Update d vector.
    normr2_new = s'*s;
    beta = normr2_new/normr2;
    normr2 = normr2_new;
    d = s + beta*d;
    X(:,j) = x;
    
    % Compute norms, if required.
    if (nargout>1), rho(j) = norm(r); end
    if (nargout>2), eta(j) = norm(x); end
    disp(rho(j)/norm(b));
    if rho(j)/norm(b) < 0.00001
        break;
    end
end

rho = rho(1:j);
eta = eta(1:j);
X = X(:,1:j);