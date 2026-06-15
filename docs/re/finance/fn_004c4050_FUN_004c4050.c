// FUN_004c4050  entry=004c4050  size=52 bytes

LPSTR __thiscall FUN_004c4050(LPSTR param_1,LPCSTR param_2)

{
  LPSTR pCVar1;
  
  lstrcpyA(param_1,param_2);
  pCVar1 = param_1 + 1;
  do {
    *pCVar1 = pCVar1[(int)param_2 - (int)param_1];
    pCVar1 = pCVar1 + 1;
  } while (pCVar1 + (-1 - (int)param_1) < (LPSTR)0xff);
  return param_1;
}


