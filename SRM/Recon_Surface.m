classdef Recon_Surface
    
    properties
        x;
        y;
        z;
        xDim;
        yDim;
        zDistance;
        stepSize;
        stepSize_factor = 0.1;
        edgeSize_factor = 0.2;
        zDistance_factor = 0.05;
    end
    
    methods
        function this = Recon_Surface(aut_dim_x,aut_dim_y,freq)
            c = 299792458;
            lamda = c/freq;
            this.xDim = aut_dim_x + 2*this.edgeSize_factor*lamda;
            this.yDim = aut_dim_y + 2*this.edgeSize_factor*lamda;
            this.zDistance = this.zDistance_factor * lamda;
            this.stepSize = this.stepSize_factor * lamda;
            
            [this.x,this.y,this.z] = recon_plane_generaor(this);
            
        end
        
        function [x,y,z] = recon_plane_generaor(obj)
            
            [X_recon, Y_recon] = meshgrid(-obj.xDim/2:obj.stepSize:obj.xDim/2,...
                -obj.yDim/2:obj.stepSize:obj.yDim/2);
            Z_recon = ones(size(X_recon))*obj.zDistance;
            x = reshape(X_recon,[],1);
            y = reshape(Y_recon,[],1);
            z = reshape(Z_recon,[],1);
        end
        
        function plot_reconSurf(obj)
            figure;
            scatter(obj.x,obj.y,10,'filled');
            axis('equal');
            xlabel('x');
            ylabel('y');
            title('Recon Surface');
        end
    end
    
end

