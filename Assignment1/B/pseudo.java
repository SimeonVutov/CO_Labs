import java.util.Scanner;

/**
 * pseudo
 */
public class pseudo {

    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        int base = sc.nextInt();
        int exp = sc.nextInt();

        // pow
        int total = 1;
        while(exp > 0) {
            total *= base;
            exp--;
        }
        // end

        System.out.println(total);
    }
}
