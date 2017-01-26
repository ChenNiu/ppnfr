classdef PPNFR_NF_Measurement 
    properties
        filename;
        freq;
        ifbw;
        num;
        num_Enor = 0;
        num_Etan = 0;
        time;
        x;
        y;
        z;
        aut_dim_x;
        aut_dim_y;
        aut_dim_z;
        penAng;
        autAng;
        phaseAng;
        S21;
        S21_dB;
        isNorm;
    end
    
    methods
        function this = PPNFR_NF_Measurement(filename)
            this.filename = filename;
            fid = fopen(this.filename);
            if fid>0
                firstLine = fgetl(fid);
                secondLine = fgetl(fid);
                fclose(fid);
                format = '%*s = %f%*s %*s = %f%*s %*s = %f%*s';
                [this.freq,this.ifbw,z] = strread(firstLine,format);
                format = '%*s %*s %*s %f, %f, %f';
                [this.aut_dim_x,this.aut_dim_y,this.aut_dim_z] = strread(secondLine,format);
                this.freq = this.freq * 1e9;
                this.ifbw = this.ifbw * 1e3;
                mat = csvread(filename,2,0);
                this.num = size(mat,1);
                this.time = mat(:,1);
                this.x = mat(:,2);
                this.y = mat(:,3);
                this.z = ones(this.num,1)*z;
                this.penAng = mat(:,4);
                this.autAng = mat(:,5);
                this.phaseAng = mat(:,6);
                this.S21 = complex(mat(:,7),mat(:,8));
                this.S21_dB = 20*log10(abs(this.S21));
                this.isNorm = mat(:,9);
                for i=1:this.num
                    if this.isNorm(i)
                        this.num_Enor = this.num_Enor + 1;
                    else
                        this.num_Etan = this.num_Etan + 1;
                    end
                end
            else
                error('can not open ppnfr file.');
            end
        end
        
        function plot_xy_S21_dB_Enor(obj)
            figure;
            scatter(obj.x(1:obj.num_Enor),obj.y(1:obj.num_Enor),10,obj.S21_dB(1:obj.num_Enor),'filled');
            axis('equal');
            xlabel('x');
            ylabel('y');
            title('S21 dB Enor');
        end
        
        function plot_xyS21_dB_Etan(obj)
            figure;
            scatter(obj.x(obj.num_Enor+1:end),obj.y(obj.num_Enor+1:end),20,obj.S21_dB(obj.num_Enor+1:end),'filled');
            axis('equal');
            xlabel('x');
            ylabel('y');
            title('S21 dB Etan');
        end
        
        function plot_autAng_penAng_S21_dB_Enor(obj)
            figure;
            scatter(obj.autAng(1:obj.num_Enor),obj.penAng(1:obj.num_Enor),20,obj.S21_dB(1:obj.num_Enor),'filled');
            xlabel('autAng');
            ylabel('penAng');
            title('S21 dB Enor');
        end
        
        function plot_autAng_penAng_S21_dB_Etan(obj)
            figure;
            scatter(obj.autAng(obj.num_Enor+1:end),obj.penAng(obj.num_Enor+1:end),20,obj.S21_dB(obj.num_Enor+1:end),'filled');
            xlabel('autAng');
            ylabel('penAng');
            title('S21 dB Etan');
        end
        
        function plot_phaseAng(obj)
            figure;
            quiver(obj.x,obj.y,cosd(obj.phaseAng),sind(obj.phaseAng));
            axis('equal');
        end
    end
    
end

