// FUN_005e6120  entry=005e6120  size=177 bytes

char * FUN_005e6120(char *param_1,char *param_2,int param_3)

{
  char cVar1;
  int iVar2;
  uint uVar3;
  uint uVar4;
  char *pcVar5;
  char *pcVar6;
  
  pcVar5 = param_1;
  if (*param_1 != '\0') {
    uVar3 = 0xffffffff;
    do {
      if (uVar3 == 0) break;
      uVar3 = uVar3 - 1;
      cVar1 = *pcVar5;
      pcVar5 = pcVar5 + 1;
    } while (cVar1 != '\0');
    pcVar5 = param_1 + (~uVar3 - 2);
  }
  if (param_1 <= pcVar5) {
    while ((*pcVar5 != '\\' && (*pcVar5 != '/'))) {
      pcVar6 = pcVar5 + -1;
      iVar2 = FUN_005e60f0(pcVar6);
      if ((iVar2 != 0) || (pcVar5 = pcVar6, pcVar6 < param_1)) break;
    }
  }
  if ((*pcVar5 == '.') && (pcVar5 = param_1, *param_1 != '\0')) {
    uVar3 = 0xffffffff;
    do {
      if (uVar3 == 0) break;
      uVar3 = uVar3 - 1;
      cVar1 = *pcVar5;
      pcVar5 = pcVar5 + 1;
    } while (cVar1 != '\0');
    pcVar5 = param_1 + (~uVar3 - 2);
  }
  if (param_2 == (char *)0x0) {
    return pcVar5 + 1;
  }
  if (param_3 != 0) {
    FUN_005f9660(param_2,param_3,pcVar5 + 1);
    return param_2;
  }
  uVar3 = 0xffffffff;
  pcVar5 = pcVar5 + 1;
  do {
    pcVar6 = pcVar5;
    if (uVar3 == 0) break;
    uVar3 = uVar3 - 1;
    pcVar6 = pcVar5 + 1;
    cVar1 = *pcVar5;
    pcVar5 = pcVar6;
  } while (cVar1 != '\0');
  uVar3 = ~uVar3;
  pcVar5 = pcVar6 + -uVar3;
  pcVar6 = param_2;
  for (uVar4 = uVar3 >> 2; uVar4 != 0; uVar4 = uVar4 - 1) {
    *(undefined4 *)pcVar6 = *(undefined4 *)pcVar5;
    pcVar5 = pcVar5 + 4;
    pcVar6 = pcVar6 + 4;
  }
  for (uVar3 = uVar3 & 3; uVar3 != 0; uVar3 = uVar3 - 1) {
    *pcVar6 = *pcVar5;
    pcVar5 = pcVar5 + 1;
    pcVar6 = pcVar6 + 1;
  }
  return param_2;
}


