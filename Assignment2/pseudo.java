import java.util.Scanner;

class Main {
    public static void main(String[] args) {
        Scanner scan = new Scanner(System.in);
        int n = Integer.parseInt(scan.nextLine());
        System.out.println(factorial(n));
    }
    public static int factorial(int n){
        if(n == 1){
            return n;
        }else{
         return n * factorial(n-1);
        }
    }
}