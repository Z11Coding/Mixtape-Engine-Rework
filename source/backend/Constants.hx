package backend;

class Constants {
    // Things that dont change/change very little go here

    /* - - - BASE GAME SONGS - - */
    /**
     * Constant for the number of milliseconds in a second.
     */
    public static final MS_PER_SEC:Int = 1000;

     /**
     * Number of steps in a beat.
     * The note length of a step varies based on the time signature denominator.
     */
    public static final STEPS_PER_BEAT:Int = 4;

     /**
     * The horizontal offset of the strumline from the left edge of the screen.
     */
    public static final STRUMLINE_X_OFFSET:Float = 48;

     /**
     * The vertical offset of the strumline from the top edge of the screen.
     */
    public static final STRUMLINE_Y_OFFSET:Float = 24;

     /**
     * A magic number used when calculating scroll speed and note distances.
     */
    public static final PIXELS_PER_MS:Float = 0.45;

     /**
     * The maximum interval within which a note can be hit, in milliseconds.
     */
    public static final HIT_WINDOW_MS:Float = 160.0;

    public static final GHOST_TAP_DELAY:Float = 3 / 8;

}
