// FUN_00579170  entry=00579170  size=183 bytes

void __thiscall FUN_00579170(int *param_1,int param_2,int *param_3,int *param_4,int param_5)

{
  char *pcVar1;
  char cVar2;
  int iVar3;
  int iVar4;
  ushort *puVar5;
  
  iVar3 = *param_3;
  param_1[1] = 0;
  *(undefined2 *)(param_1 + 1) = *(undefined2 *)*param_4;
  *param_4 = *param_4 + 2;
  param_2 = param_2 + iVar3;
  *param_1 = param_2;
  iVar4 = FUN_0058c810(param_2);
  if (param_5 == 0) {
    puVar5 = (ushort *)(*(ushort *)*param_4 + 2 + *param_4);
    *param_4 = (int)puVar5;
    puVar5 = (ushort *)(*puVar5 + 2 + (int)puVar5);
    *param_4 = (int)puVar5;
    puVar5 = (ushort *)(*puVar5 + 2 + (int)puVar5);
    *param_4 = (int)puVar5;
    puVar5 = (ushort *)(*puVar5 + 2 + (int)puVar5);
    *param_4 = (int)puVar5;
    puVar5 = (ushort *)(*puVar5 + 2 + (int)puVar5);
    *param_4 = (int)puVar5;
    puVar5 = (ushort *)(*puVar5 + 2 + (int)puVar5);
    *param_4 = (int)puVar5;
    pcVar1 = (char *)(*puVar5 + 2 + (int)puVar5);
    *param_4 = (int)pcVar1;
    cVar2 = *pcVar1;
    puVar5 = (ushort *)(pcVar1 + 1);
    *param_4 = (int)puVar5;
    if (cVar2 == '\x03') {
      *param_4 = (int)(*puVar5 + 2 + (int)puVar5);
    }
    *param_4 = *(ushort *)*param_4 + 2 + *param_4;
  }
  *param_3 = iVar3 + iVar4;
  return;
}


