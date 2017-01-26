function [ recon ] = recon_plane_generaor( recon )
% recon.step is the recon plane grid spacing
% recon.dist is the distance from recon plane to antenna 
% recon.xSize is the size of the recon plane is x dimension
% recon.ySize is the size of the recon plane is y dimension
% recon.x is the vector x 
% recon.y is the vector y 
% recon.z is the vector z 

[X_recon, Y_recon] = meshgrid(-recon.xSize/2:recon.step:recon.xSize/2,...
    -recon.ySize/2:recon.step:recon.ySize/2);
Z_recon = ones(size(X_recon))*recon.dist;
recon.x = reshape(X_recon,[],1);
recon.y = reshape(Y_recon,[],1);
recon.z = reshape(Z_recon,[],1);
end

