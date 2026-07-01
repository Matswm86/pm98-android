// FUN_0058df10  entry=0058df10  size=53 bytes

LPSTR FUN_0058df10(LPSTR param_1,ulong param_2)

{
  char *lpString2;
  char local_100 [256];
  
  lpString2 = _ultoa(param_2,local_100,10);
  lstrcpyA(param_1,lpString2);
  return param_1;
}


