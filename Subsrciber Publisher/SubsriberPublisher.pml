#define subscribersCount  1

mtype:subscription = {SUBSCRIBED, UNSUBSCRIBED}
mtype:subscription subscribersStatus[subscribersCount];

mtype:subscriberRequest = {ENROLL, RELEASE}
chan request = [5] of {short, mtype:subscriberRequest};

mtype:publisherResponse = {ACCEPT, REJECT}
chan response = [5] of {short, mtype:publisherResponse};

chan publisherChannel[subscribersCount] = [0] of {int}

bool canRelease = true;

int timeCounter;

proctype publisher(){
    bit message;
    do
    :: true ->
        if
        :: ((timeCounter >= 3) && (timeCounter % 2 == 1)) -> 
            int i = 0;
            do
            :: i < subscribersCount ->
                if
                :: subscribersStatus[i] == SUBSCRIBED -> 
                    publisherChannel[i] ! message;
                :: else -> skip;
                fi

                i++;
            :: i >= subscribersCount -> break;
            od

            message = 1 - message;
        :: else -> skip;
        fi
    od
}

proctype subscriber(short id){
    subscribersStatus[id] = UNSUBSCRIBED;

    run enroll(id);

    int message;
    do
    :: publisherChannel[id] ? message -> 
        printf("Subscriber %d received message %d", id, message);
    od
}

proctype enroll(short id){
    mtype:publisherResponse result;
    short index;

    do
    :: subscribersStatus[id] == UNSUBSCRIBED -> request ! id,ENROLL;
    :: response ? index,result -> 
        if
        :: index == id ->
            if
            :: result == ACCEPT -> 
                subscribersStatus[id] = SUBSCRIBED;
                printf("Subsriber %d enrolled!", id);
                
                if
                :: canRelease == true -> run release(id); break;
                :: else -> break;;
                fi
            :: else -> 
                printf("Error while enrolling subsriber %d", id);
            fi
        :: else -> skip;
        fi
    od
}

proctype release(short id){
    mtype:publisherResponse result;
    short index;

    do
    :: subscribersStatus[id] == SUBSCRIBED -> request ! id,RELEASE;
    :: response ? index,result -> 
        if
        :: index == id ->
            if
            :: result == ACCEPT -> 
                subscribersStatus[id] = UNSUBSCRIBED;
                printf("Subsriber %d released!", id);
                run enroll(id);
                break;
            :: else -> 
                printf("Error while releasing subsriber %d", id);
            fi
        :: else -> skip;
        fi
    od
}

proctype subscriptionManager(short id){
    mtype:subscriberRequest req;
    short index;

    run subscriber(id);

    do
    :: request ? index,req -> 
        if
        :: index == id -> 
            if
            :: req == ENROLL ->
                if
                :: subscribersStatus[id] == UNSUBSCRIBED -> response ! id,ACCEPT;
                :: else -> response ! id,REJECT;
                fi
            :: req == RELEASE ->
                if
                :: subscribersStatus[id] == SUBSCRIBED -> response ! id,ACCEPT;
                :: else -> response ! id,REJECT;
                fi
            fi
        :: else -> skip;
        fi
    od
}

proctype timer(){
    do
    :: timeCounter++;
    od
}

proctype test(int id, in, out){
    printf("%d", id);
}

init{
    timeCounter = 0;

    atomic {
        run timer();
        run publisher();
        
        int i = 0;
        do
        :: i < subscribersCount ->
            run subscriptionManager(i);
            i++;
        :: i >= subscribersCount -> break;
        od
    }
}