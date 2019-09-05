classdef ExperimentsSpecimenData < handle
%Class to handle the rock data of MERID triaxial experiments. The
%experiment number has to be given while creating the class object.
%All metadata information like start and end time, comments or a
%description can be read directly from the class.
%Within the class the data will be saved in a table (metaDataTable). All
%depending variables like (description, short, etc.) are empty. They are some kind of
%proxy values to be able to work with the values as if they where saved in
%the variables.
%
% Biebricher 2019-05-13
%   * Added variable massWet incl. getter
    
    properties (SetAccess = immutable)
        experimentNo; %Number of the experiment the data in this object contains to.
    end
    
    properties (SetAccess = private)
        specimen; %Proxyvariable for name of specimen in rockdata. Data is only saved in rockDataTable.
        rockType; %Proxyvariable for name of rock in rockdata. Data is only saved in rockDataTable.
        rockDescription; %Proxyvariable for rock description in rockdata. Data is only saved in rockDataTable.
        height; %Proxyvariable for height of specimen in rockdata. Data is only saved in rockDataTable.
        diameter; %Proxyvariable for diameter of specimen in rockdata. Data is only saved in rockDataTable.
        massSaturated; %Proxyvariable for mass of saturated specimen in rockdata. Data is only saved in rockDataTable.
        massWet; %Proxyvariable for mass of wet specimen in rockdata. Data is only saved in rockDataTable.
        massDry; %Proxyvariable for mass of dry specimen in rockdata. Data is only saved in rockDataTable.
        rockDensityWet; %Proxyvariable for wet rock density in rockdata. Data is only saved in rockDataTable.
        rockDensitySatturated; %Proxyvariable for wet rock density in rockdata. Data is only saved in rockDataTable.
        rockDensityDry; %Proxyvariable for wet rock density in rockdata. Data is only saved in rockDataTable.
        rockDensityGrain; %Proxyvariable for wet rock density in rockdata. Data is only saved in rockDataTable.
        densityDry;
        densitySaturated;
        permeabilityCoefficient; %Proxyvariable for permeability coefficient of rock in rockdata. Data is only saved in rockDataTable.
        porosity; %Proxyvariable for porosity of rock in rockdata. Data is only saved in rockDataTable.
        voidRatio; %Proxyvariable for void ratio of rock in rockdata. Data is only saved in rockDataTable.
        uniAxialCompressiveStrength; %Proxyvariable for uni axial compressive strength of rock in rockdata. Data is only saved in rockDataTable.
        uniAxialEModulus; %Proxyvariable for e module of uni axial compressive strength test of rock in rockdata. Data is only saved in rockDataTable.
        dataTable; %Table containing all rockdata from database
        dataTable_comparison
    end
    
    methods
        function obj = ExperimentsSpecimenData(experimentNo)
        %The experiment number (immutable) has to be set int the constructor and can
        %not be changed later.
            obj.experimentNo = experimentNo;
        end
        
        %SETTER
        function obj = setDataAsTable(obj, dataTable)
        %Set all metadata for the experiment into the object.
        %Input parameter: table with rockData
            obj.dataTable = dataTable;
            
            obj.dataTable.Properties.VariableUnits{'height'} = 'cm';
            obj.dataTable.Properties.VariableUnits{'diameter'} = 'cm';
            obj.dataTable.Properties.VariableUnits{'mass_sat'} = 'kg';
            obj.dataTable.Properties.VariableUnits{'mass_wet'} = 'kg';
            obj.dataTable.Properties.VariableUnits{'mass_dry'} = 'kg';
            obj.dataTable.Properties.VariableUnits{'density_wet'} = 'g/cm³';
            obj.dataTable.Properties.VariableUnits{'density_sat'} = 'g/cm³';
            obj.dataTable.Properties.VariableUnits{'density_dry'} = 'g/cm³';
            obj.dataTable.Properties.VariableUnits{'density_grain'} = 'g/cm³';
            obj.dataTable.Properties.VariableUnits{'perm_coeff'} = 'm/s';
            obj.dataTable.Properties.VariableUnits{'porosity'} = '-';
            obj.dataTable.Properties.VariableUnits{'void_ratio'} = '-';
            obj.dataTable.Properties.VariableUnits{'uniAx_comp_strength'} = 'kN/m²';
            obj.dataTable.Properties.VariableUnits{'uniAx_emodulus'} = 'kN/m²';
            
            
            disp([class(obj), ': ', 'Data set sucessfully']);
        end
        
        %GETTER
        function experimentNo = get.experimentNo(obj) 
            experimentNo = obj.experimentNo;
        end
        
        function specimen = get.specimen(obj) 
            specimen = obj.dataTable.specimen_name{1};
        end
        
        function rockType = get.rockType(obj) 
            rockType = obj.dataTable.rock_name{1};
        end
        
        function rockDescription = get.rockDescription(obj) 
            rockDescription = obj.dataTable.description{1};
        end
        
        function height = get.height(obj) 
            height = obj.dataTable.height;
        end
        
        function diameter = get.diameter(obj) 
            diameter = obj.dataTable.diameter;
        end
        
        function massSaturated = get.massSaturated(obj) 
            massSaturated = obj.dataTable.mass_sat;
        end
        
        function massDry = get.massDry(obj) 
            massDry = obj.dataTable.mass_dry;
        end
        
        function massWet = get.massWet(obj) 
            massWet = obj.dataTable.mass_wet;
        end
        
        function densityWet = get.rockDensityWet(obj) 
            densityWet = obj.dataTable.density_wet;
        end
        
        function density = get.rockDensitySatturated(obj) 
            density = obj.dataTable.density_sat;
        end
        
        function density = get.rockDensityDry(obj) 
            density = obj.dataTable.density_dry;
        end
        
        function density = get.rockDensityGrain(obj) 
            density = obj.dataTable.density_grain;
        end
        
        function densityDry = get.densityDry(obj) 
            densityDry = obj.dataTable.mass_wet/(obj.dataTable.height*pi*(obj.dataTable.diameter/2)^2);
        end
        
        function densitySaturated = get.densitySaturated(obj) 
            densitySaturated = obj.dataTable.mass_sat/(obj.dataTable.height*pi*(obj.dataTable.diameter/2)^2);
        end
        
        function permeabilityCoefficient = get.permeabilityCoefficient(obj) 
            permeabilityCoefficient = obj.dataTable.perm_coeff;
        end
        
        function porosity = get.porosity(obj) 
            porosity = obj.dataTable.porosity;
        end
        
        function voidRatio = get.voidRatio(obj) 
            voidRatio = obj.dataTable.void_ratio;
        end
        
        function uniAxialCompressiveStrength = get.uniAxialCompressiveStrength(obj) 
            uniAxialCompressiveStrength = obj.dataTable.uniAx_comp_strength;
        end
        
        function uniAxialEModulus = get.uniAxialEModulus(obj) 
            uniAxialEModulus = obj.dataTable.uniAx_emodulus;
        end
        
        
    end
end