classdef En_DrvMode < Simulink.IntEnumType
  enumeration
    ECO(0)
    NORMAL(1)
    SPORT(2)
  end
  methods (Static)
    function retVal = getDefaultValue(), retVal = En_DrvMode.ECO; end
    function retVal = getDescription(), retVal = 'En_DrvMode from dd Enum sheet'; end
    function retVal = getDataScope(), retVal = 'Auto'; end
    function retVal = getHeaderFile(), retVal = 'Rte_Type.h'; end
    function retVal = addClassNameToEnumNames(), retVal = false; end
  end
end
