clc
close all
clear all

symbol ={'R0';'R1';'R2';'R3';'R4';'R5';'R6';'R7';'R8';'R9';'R10';'R11';'R12';'R13';'R14';'R15';'SCREEN';'KBD';'SP';'LCL';'ARG';'THIS';'THAT'};
Address={'0';'1';'2';'3';'4';'5';'6';'7';'8';'9';'10';'11';'12';'13';'14';'15';'16384';'24576';'0';'1';'2';'3';'4'};
symboltable=table(symbol,Address);% Symbol table created

d={':';'M';'D';'MD';'A';'AM';'AD';'AMD'};
d_address={'000';'001';'010';'011';'100';'101';'110';'111'};
dcode=table(d,d_address);         % D instruction table created

c={'0';'1';'-1';'D';'A';'M';'!D';'!A';'!M';'-D';'-A';'-M';'D+1';'A+1';'M+1';'D-1';'A-1';'M-1';'D+A';'D+M';'D-A';'D-M';'A-D';'M-D';'D&A';'D&M';'D|A';'D|M';'A+D'};
c_address={'0101010';'0111111';'0111010';'0001100';'0110000';'1110000';'0001101';'0110001';'1110001';'0001111';'0110011';'1110011';'0011111';'0110111';'1110111';'0001110';'0110010';'1110010';'0000010';'1000010';'0010011';'1010011';'0000111';'1000111';'0000000';'1000000';'0010101';'1010101';'0000010'};
ccode=table(c,c_address);         % C instruction table created

jump={'';'JGT';'JEQ';'JGE';'JLT';'JNE';'JLE';'JMP'};
jumpaddress={'000';'001';'010';'011';'100';'101';'110';'111'};
jumpcode=table(jump,jumpaddress); % Jump instruction table created

prompt = 'Input file name ';
str = input(prompt,'s');
fid = fopen(str);
tline = fgetl(fid);
interfinalcode={}; % Storing code without label
finalcode={};      % Storing code with label

i=1; % for semifinalcode and final code
y=1; % for interfinal code

% stage 1
% filtering started to remove white spaces and comments
while ischar(tline)
    k1 = strfind(tline,'//'); % Checks for '//'
    k2 = isempty(tline);      % Checks for empty spaces
    k3 = strfind(tline,'(');  % Checks for '('
    
    if k1==1 
        %disp('comment');
    elseif k2==1
        %disp('empty');
    elseif k3==1
        tline = strtok(tline, '/');% trim line after '/'
        finalcode{i}=tline;        % Storing code with label
        i=i+1;
    else     
        tline = tline(find(~isspace(tline))); % remove space
        newtline = strtok(tline, '/');        % remove comments after '/'
        k3 = strfind(newtline,'@'); % checks for '@'
        if k3==1
         instr= instructionType(newtline);
         finalcode{i}=instr;      % Storing code with label
         interfinalcode{y}=instr; % Storing code without label
         i=i+1;
         y=y+1;
        else
         finalcode{i}=newtline;      % code with label
         interfinalcode{y}=newtline; % code without label
         i=i+1;
         y=y+1;
        end
    end
    tline = fgetl(fid);
end
fclose(fid);

i=1;
new_register=16;

% stage 2
for x=1:length(interfinalcode)
    count=0;
    tf = isstrprop(interfinalcode{x},'digit');% checks the input is digit
    k5 = contains(interfinalcode{x},'=');     % checks whole line contain '= 'symbol
    k6 = strfind(interfinalcode{x},'@');% checks whole line have ' @'symbol
    if k6==1 % A instruction conversion starts for symbols already in symbol table
    
       trim_Ainstruction = strip(interfinalcode{x},'left','@');% trim @
       k7 = ismember(trim_Ainstruction,symboltable.symbol);    % checks symbol table and retuns
       newtrim="("+trim_Ainstruction+")";

        if k7==1 % A instruction conversion starts for symbols which is in symbol table
          out = dec2bin(str2double(symboltable.Address(strcmp(symboltable.symbol,trim_Ainstruction))),16);
          % converts symbol from decimal to binary those lines already in
          % symbol table
          result{i}=out;% Store final result
        else % A instruction conversion starts for symbols not in symbol table those who have label
           for v=1:length(finalcode)
                 
                 k12 = contains(finalcode{v},'('); % checking for labels 
                 if k12==0
                     count=count+1;
                 end
                 if finalcode{v}==newtrim
                     disp(newtrim)
                     out=dec2bin(count,16);
                     d2s=int2str(count);% converting decimal to binary
                     result{i}=out;% Store final result
                     new={trim_Ainstruction,d2s}; % Added new row
                     symboltable=[symboltable;new] ; % inserting new symbols into symbol table 
                 end
             end
        end
    
    elseif tf==1
        result{i}=interfinalcode{x}; % Store final result those who already converted to binary in first stage
    elseif k5==1 % C instruction conversion starts
        %disp('c instruction found');
        first  ='111';
        jumpbin='000';
        csecond_comp= extractAfter(interfinalcode{x},"=");%Take value after '='
        cfirst_dest = extractBefore(interfinalcode{x},"=");%Take value before '='
        dest        = dcode.d_address(strcmp(dcode.d,cfirst_dest));
        comp        = ccode.c_address(strcmp(ccode.c,csecond_comp));
        out         = dec2bin(uint16(bin2dec(strcat(first,comp,dest,jumpbin))));% to merge and convert string to binary
        result{i}=out; % Store final result

    else  %c instruction jump conversion starts
          %disp('jump found');
          first='111';
          dest ='000'; % jump instruction conversion starts
          jsecond_comp= extractAfter(interfinalcode{x},";");%Take value after ';'
          jfirst_jump = extractBefore(interfinalcode{x},";");%Take value before ';'
          jumpbin     = jumpcode.jumpaddress(strcmp(jumpcode.jump,jsecond_comp));
          comp        = ccode.c_address(strcmp(ccode.c,jfirst_jump));
          out         = dec2bin(uint16(bin2dec(strcat(first,comp,dest,jumpbin))));% used to combine string
          result{i}=out; % Store final result
    end
    i=i+1;
end

% stage 3

for x=1:length(interfinalcode)% A instruction conversion starts for symbols not in symbol table and dont have label
  k14 = strfind(interfinalcode{x},'@');
  if k14==1 % A instruction conversion starts for symbols not in in symbol table and not have a label
     trim_Ainstruction = strip(interfinalcode{x},'left','@');% trim @
     k15 = ismember(trim_Ainstruction,symboltable.symbol);% checks for A instruction in symbol table
     if k15==0
      out=dec2bin(new_register,16);% convert decimal to binary
      d2s=int2str(new_register);% convert integer to string
      result{x}=out; % Store final result
      new={trim_Ainstruction,d2s};
      symboltable=[symboltable;new] ;% inserting new symbols into symbol table
      new_register=new_register+1;%incrementing register
     else
      out = dec2bin(str2double(symboltable.Address(strcmp(symboltable.symbol,trim_Ainstruction))),16);
      result{x}=out; % Store final result
     end
  end
end

% stage 4
% .hack file creation starts
fid=fopen([str(1:end-4) '.hack'],'w');
for x=1:length(result)
    fprintf(fid, [ result{x} '\n']);
end
fclose(fid);

disp(symboltable)% final symbol table

% function 1
function res = instructionType(instruction) % function to process A instruction
    newstr=strip(instruction,'left','@');% trim @
    tf = isstrprop(newstr,'digit');      % check for integer
    if tf==1
        k= str2num(string(newstr));
        k = dec2bin(k,16) ; % Converts A instruction those who have decimal value
        res = k;   % returns binary value
    else
        res=instruction; % returns A instruction
    end
end









