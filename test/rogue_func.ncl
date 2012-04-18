function a_rogue_function(a,b,c)
begin
  a=a+1  ; not the right way to do
         ; since NCL function arguments
         ; have global scope
         ; changing their value inside the function
         ; would result in their value being
         ; changed elsewhere - it is undesireable
  return(a+b+c)
end
