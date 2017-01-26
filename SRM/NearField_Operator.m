classdef NearField_Operator
    properties
        A;
        recon; 
        nf; 
        freq;
    end
    
    methods
        function this = NearField_Operator(reconSurf,nfMeas,freq)
            this.recon.x = reconSurf.x;
            this.recon.y = reconSurf.y;
            this.recon.z = reconSurf.z;
            this.nf.x = nfMeas.x;
            this.nf.y = nfMeas.y;
            this.nf.z = nfMeas.z;
            this.nf.theta = nfMeas.phaseAng*pi/180;
            this.freq = freq;
            this.A = nf_operatorMat_generator( this.recon, this.nf, this.freq );
        end
        
    end
    
end

