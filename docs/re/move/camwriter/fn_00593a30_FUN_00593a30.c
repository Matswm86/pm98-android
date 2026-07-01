// FUN_00593a30  entry=00593a30  size=120 bytes

void __fastcall FUN_00593a30(int param_1)

{
  char cVar1;
  undefined1 uVar2;
  
  cVar1 = *(char *)(param_1 + 0x180e);
  if ((cVar1 == '\0') || (*(int *)(*(int *)(param_1 + 0x468) + 0xff0) == 0)) {
    uVar2 = 0;
  }
  else {
    uVar2 = 1;
  }
  *(undefined1 *)(param_1 + 0x180b) = uVar2;
  if ((cVar1 == '\0') || (*(int *)(*(int *)(param_1 + 0x468) + 0xfe8) == 0)) {
    uVar2 = 0;
  }
  else {
    uVar2 = 1;
  }
  *(undefined1 *)(param_1 + 0x180a) = uVar2;
  if ((cVar1 != '\0') && (*(int *)(*(int *)(param_1 + 0x468) + 0xfec) != 0)) {
    *(undefined1 *)(param_1 + 0x180c) = 1;
    return;
  }
  *(undefined1 *)(param_1 + 0x180c) = 0;
  return;
}


