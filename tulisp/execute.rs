use std::rc::Rc;

#[derive(Clone)]
pub enum Value
{
    Int(i64),
    Str(Rc<[u8]>),
}

#[derive(Clone, Copy)]
pub enum Instr
{
    LdErrno,
    SysClose,
    SysExit,
    SysSocket,
    SysWrite,
}

pub fn executeInstr(stack: &mut Vec<Value>, instr: Instr)
{
    match instr {
        Instr::LdErrno => {
            let result = unsafe { *libc::__errno_location() };
            pushInt(stack, result as i64);
        },

        Instr::SysClose => {
            let fd      = popInt(stack) as libc::c_int;
            let result  = unsafe { libc::close(fd) };
            pushInt(stack, result as i64);
        },

        Instr::SysExit => {
            let status = popInt(stack) as libc::c_int;
            unsafe { libc::_exit(status) };
        },

        Instr::SysSocket => {
            let protocol = popInt(stack) as libc::c_int;
            let r#type   = popInt(stack) as libc::c_int;
            let domain   = popInt(stack) as libc::c_int;
            let result   = unsafe { libc::socket(domain, r#type, protocol) };
            pushInt(stack, result as i64);
        },

        Instr::SysWrite => {
            let slice  = popStr(stack);
            let fd     = popInt(stack) as libc::c_int;
            let buf    = slice.as_ptr() as *const libc::c_void;
            let count  = slice.len();
            let result = unsafe { libc::write(fd, buf, count) };
            pushInt(stack, result as i64);
        },
    }
}

fn pushInt(stack: &mut Vec<Value>, int: i64)
{
    let value = Value::Int(int);
    stack.push(value);
}

fn popInt(stack: &mut Vec<Value>) -> i64
{
    match stack.pop() {
        Some(Value::Int(int)) => int,
        Some(_) => panic!("Top of stack is not an int"),
        None    => panic!("Stack is empty"),
    }
}

fn popStr(stack: &mut Vec<Value>) -> Rc<[u8]>
{
    match stack.pop() {
        Some(Value::Str(str)) => str.clone(),
        Some(_) => panic!("Top of stack is not a str"),
        None    => panic!("Stack is empty"),
    }
}
