classdef FarField_Operator

    properties
        A;
        recon;
        ff;
        freq;
    end
    
    methods
        function this = FarField_Operator(reconSurf, phi, dtheta, freq)
            c = 299792458;
            lamda = c/freq;
            this.recon.x = reconSurf.x;
            this.recon.y = reconSurf.y;
            this.recon.z = reconSurf.z;
            this.freq = freq;
            this.ff.phi = phi;
            this.ff.theta = -90:dtheta:90;
            this.ff.r = 100*lamda;
            
            % outer product theta is vec, phi is roll
            this.ff.x = this.ff.r*sind(this.ff.theta)*cosd(this.ff.phi)';
            this.ff.y = this.ff.r*sind(this.ff.theta)*sind(this.ff.phi)';
            this.ff.z = this.ff.r*cosd(this.ff.theta)*ones(1,length(this.ff.phi));
            % unroll the matrix
            this.ff.x = reshape(this.ff.x,[],1);
            this.ff.y = reshape(this.ff.y,[],1);
            this.ff.z = reshape(this.ff.z,[],1);
            
            this.A = ff_operatorMat_generator( this.recon, this.ff, this.freq );
        end
        
    end
    
end

