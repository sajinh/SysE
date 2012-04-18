load "test/rogue_func.ncl"
undef(" a_rogue_function")
function a_rogue_function(a,b,c)
begin
  ;copying function argument to temporary variable
  __a=a
  a=a+1  ; not the right way to do
         ; since NCL function arguments
         ; have global scope
         ; changing their value inside the function
         ; would result in their value being
         ; changed elsewhere - it is undesireable
  ;copying back function argument from temporary variable
  a=__a
  return(a+b+c)
end
