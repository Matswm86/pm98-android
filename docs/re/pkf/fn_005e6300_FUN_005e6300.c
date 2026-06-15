// FUN_005e6300  entry=005e6300  size=99 bytes

undefined4 FUN_005e6300(int param_1,char *param_2,char *param_3,uint param_4)

{
  char cVar1;
  char *pcVar2;
  size_t _Count;
  int iVar3;
  
  cVar1 = *param_2;
  pcVar2 = param_2;
  if (cVar1 == '\0') {
    return 0;
  }
  while (((cVar1 != '\\' && (iVar3 = param_1, cVar1 != '/')) || (iVar3 = param_1 + -1, param_1 != 0)
         )) {
    cVar1 = pcVar2[1];
    pcVar2 = pcVar2 + 1;
    param_1 = iVar3;
    if (cVar1 == '\0') {
      return 0;
    }
  }
  _Count = (int)pcVar2 - (int)param_2;
  if (1 < _Count) {
    if (param_4 <= _Count) {
      _Count = param_4 - 1;
    }
    strncpy(param_3,param_2,_Count);
    param_3[_Count] = '\0';
  }
  return 1;
}


