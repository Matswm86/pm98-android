// FUN_005f9660  entry=005f9660  size=115 bytes

char * FUN_005f9660(char *param_1,uint param_2,char *param_3)

{
  char cVar1;
  uint uVar2;
  uint uVar3;
  size_t _Count;
  char *pcVar4;
  char *pcVar5;
  
  if (((param_1 == (char *)0x0) || (param_3 == (char *)0x0)) || (param_2 == 0)) {
    return (char *)0x0;
  }
  uVar2 = 0xffffffff;
  pcVar4 = param_3;
  do {
    if (uVar2 == 0) break;
    uVar2 = uVar2 - 1;
    cVar1 = *pcVar4;
    pcVar4 = pcVar4 + 1;
  } while (cVar1 != '\0');
  _Count = param_2 - 1;
  if (param_2 <= ~uVar2 - 1) {
    if (_Count != 0) {
      strncpy(param_1,param_3,_Count);
    }
    param_1[_Count] = '\0';
    return (char *)0x0;
  }
  uVar2 = 0xffffffff;
  do {
    pcVar4 = param_3;
    if (uVar2 == 0) break;
    uVar2 = uVar2 - 1;
    pcVar4 = param_3 + 1;
    cVar1 = *param_3;
    param_3 = pcVar4;
  } while (cVar1 != '\0');
  uVar2 = ~uVar2;
  pcVar4 = pcVar4 + -uVar2;
  pcVar5 = param_1;
  for (uVar3 = uVar2 >> 2; uVar3 != 0; uVar3 = uVar3 - 1) {
    *(undefined4 *)pcVar5 = *(undefined4 *)pcVar4;
    pcVar4 = pcVar4 + 4;
    pcVar5 = pcVar5 + 4;
  }
  for (uVar2 = uVar2 & 3; uVar2 != 0; uVar2 = uVar2 - 1) {
    *pcVar5 = *pcVar4;
    pcVar4 = pcVar4 + 1;
    pcVar5 = pcVar5 + 1;
  }
  return param_1;
}


