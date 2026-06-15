// FUN_005e6370  entry=005e6370  size=162 bytes

char * FUN_005e6370(undefined4 param_1,undefined4 param_2,char *param_3,undefined4 param_4)

{
  char cVar1;
  uint uVar2;
  uint uVar3;
  char *pcVar4;
  char *pcVar5;
  char *pcVar6;
  
  FUN_005f9660(param_3,param_4,param_1);
  if (*param_3 == '\0') {
    FUN_005f9660(param_3,param_4,param_2);
    FUN_005f97e0(param_3);
    return param_3;
  }
  uVar2 = 0xffffffff;
  pcVar4 = param_3;
  do {
    if (uVar2 == 0) break;
    uVar2 = uVar2 - 1;
    cVar1 = *pcVar4;
    pcVar4 = pcVar4 + 1;
  } while (cVar1 != '\0');
  cVar1 = param_3[~uVar2 - 2];
  pcVar4 = param_3 + (~uVar2 - 2);
  if (((cVar1 != '\\') && (cVar1 != '/')) && (cVar1 != ':')) {
    uVar2 = 0xffffffff;
    pcVar4 = pcVar4 + 1;
    pcVar5 = &DAT_00657ab0;
    do {
      pcVar6 = pcVar5;
      if (uVar2 == 0) break;
      uVar2 = uVar2 - 1;
      pcVar6 = pcVar5 + 1;
      cVar1 = *pcVar5;
      pcVar5 = pcVar6;
    } while (cVar1 != '\0');
    uVar2 = ~uVar2;
    pcVar5 = pcVar6 + -uVar2;
    pcVar6 = pcVar4;
    for (uVar3 = uVar2 >> 2; uVar3 != 0; uVar3 = uVar3 - 1) {
      *(undefined4 *)pcVar6 = *(undefined4 *)pcVar5;
      pcVar5 = pcVar5 + 4;
      pcVar6 = pcVar6 + 4;
    }
    for (uVar2 = uVar2 & 3; uVar2 != 0; uVar2 = uVar2 - 1) {
      *pcVar6 = *pcVar5;
      pcVar5 = pcVar5 + 1;
      pcVar6 = pcVar6 + 1;
    }
  }
  FUN_005f96e0(param_3,param_4,pcVar4 + 1,param_2);
  FUN_005f97e0(param_3);
  return param_3;
}


