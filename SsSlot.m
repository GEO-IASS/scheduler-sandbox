classdef SsSlot < handle
    % Receiver for other objects that we want to plug in.
    
    properties
        name;
        acceptedClass;
        requiredProperties;
        object;
    end
    
    methods
        function obj = SsSlot(name, acceptedClass)
            parser = SsInputParser();
            parser.addRequired('name', @ischar);
            parser.addRequired('acceptedClass', @ischar);
            parser.parseMagically(obj, name, acceptedClass);
        end
        
        function obj = requireProperty(obj, name, varargin)
            parser = SsInputParser();
            parser.addRequired('name', @ischar);
            parser.addParameter('units', '', @ischar);
            parser.addParameter('validator', [], @(v) isempty(v) || isa(v, 'function_handle'));
            requirement = parser.parseMagically(struct(), name, varargin{:});
            
            if isempty(obj.requiredProperties)
                obj.requiredProperties = requirement;
            else
                obj.requiredProperties(end+1) = requirement;
            end
        end
        
        function accepted = offer(obj, offering)
            accepted = obj.validateOffering(offering);
            if accepted
                obj.object = offering;
            end
        end
    end
    
    methods (Access = private)
        function accepted = validateOffering(obj, offering)
            accepted = false;
            
            if ~isa(offering, obj.acceptedClass)
                warning('Slot:incorrectClass', ...
                    'Offering has class "%s: but should be "%s".', ...
                    class(offering), obj.acceptedClass);
            end
            
            nRequirements = numel(obj.requiredProperties);
            for rr = 1:nRequirements
                requirement = obj.requiredProperties(rr);
                if ~isprop(offering, requirement.name) ...
                        && ~isfield(offering, requirement.name)
                    warning('Slot:missingProperty', ...
                        'Offering lacks required property "%s".', requirement.name);
                    return;
                end
                
                value = offering.(requirement.name);
                
                if ~isempty(requirement.units)
                    if ~isprop(value, 'units') && ~isfield(value, 'units')
                        warning('Slot:missingUnits', ...
                            'Property "%s" lacks units field.', requirement.name);
                        return;
                    end
                    
                    if ~strcmp(requirement.units, value.units)
                        warning('Slot:wrongUnits', ...
                            'Property "%s" has units "%s" but should be "%s".', ...
                            requirement.name, value.units, requirement.units);
                        return;
                    end
                end
                
                if ~isempty(requirement.validator) ...
                        && ~feval(requirement.validator, value)
                    warning('Slot:invalidValue', ...
                        'Property "%s" failed validation "%s".', ...
                        requirement.name, func2str(requirement.validator));
                    return;
                end
                
            end
            accepted = true;
        end
    end
end
