classdef SsPointOfView < SsEntity
    % Parameters to describe how to view a scene.
    
    properties
        distance;
        fieldOfView;
    end
    
    methods
        function obj = SsPointOfView(varargin)
            parser = SsInputParser();
            parser.addParameter('name', '', @ischar);
            parser.addParameter('distance', 1, @isnumeric);
            parser.addParameter('fieldOfView', pi()/24, @isnumeric);
            parser.parseMagically(obj, varargin{:});
        end
    end
end
