// FUN_0044c400  entry=0044c400  size=144 bytes

void __cdecl FUN_0044c400(int param_1,int *param_2,undefined1 *param_3,int param_4)

{
  char cVar1;
  int iVar2;
  int iVar3;
  
  iVar3 = 0;
  *param_3 = 0;
  while( true ) {
    while( true ) {
      cVar1 = *(char *)(param_1 + *param_2);
      if ((cVar1 == '\r') && (*(char *)(param_1 + *param_2 + 1) == '\n')) {
        iVar2 = *param_2 + 2;
        goto LAB_0044c463;
      }
      if (cVar1 != ',') break;
      if (param_4 == 0) goto LAB_0044c45a;
      param_3[iVar3] = 0x2c;
      iVar3 = iVar3 + 1;
      *param_2 = *param_2 + 1;
    }
    if (cVar1 == '\0') break;
    param_3[iVar3] = cVar1;
    iVar3 = iVar3 + 1;
    *param_2 = *param_2 + 1;
  }
LAB_0044c45a:
  if (*(char *)(param_1 + *param_2) == ',') {
    iVar2 = *param_2 + 1;
LAB_0044c463:
    *param_2 = iVar2;
  }
  param_3[iVar3] = 0;
  iVar3 = *param_2;
  cVar1 = *(char *)(param_1 + iVar3);
  while ((cVar1 == '\r' || (cVar1 == '\n'))) {
    iVar3 = iVar3 + 1;
    *param_2 = iVar3;
    cVar1 = *(char *)(param_1 + iVar3);
  }
  return;
}


