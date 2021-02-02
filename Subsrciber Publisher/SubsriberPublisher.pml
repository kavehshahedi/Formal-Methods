#define subscribersCount  5

mtype:subscription = {SUBSCRIBED, UNSUBSCRIBED}
mtype:subscription subscribersStatus[subscribersCount];

mtype:subscriberRequest = {ENROLL, RELEASE}
chan requests[subscribersCount] = [subscribersCount] of {mtype:subscriberRequest};

mtype:publisherResponse = {ACCEPT, REJECT}
chan responses[subscribersCount] = [subscribersCount] of {mtype:publisherResponse};

chan publisherChannel[subscribersCount] = [0] of {int}

int timeCounter;

proctype publisher(){
    bit message;
    do
    :: true ->
        if
        :: ((timeCounter >= 3) && (timeCounter % 2 == 1)) -> 
            int i;
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

    int message;
    do
    :: publisherChannel[id] ? message -> 
        printf("Subscriber %d received message %d", id, message);
    od
}

proctype enroll(short id){
    mtype:publisherResponse response;

    do
    :: subscribersStatus[id] == UNSUBSCRIBED -> requests[id] ! ENROLL;
    :: responses[id] ? response -> 
        if
        :: response == ACCEPT -> 
            subscribersStatus[id] = SUBSCRIBED;
            printf("Subsriber %d enrolled!", id);
            break;
        :: else -> 
            printf("Error while enrolling subsriber %d", id);
        fi
    od
}

proctype release(short id){
    mtype:publisherResponse response;

    do
    :: subscribersStatus[id] == SUBSCRIBED -> requests[id] ! RELEASE;
    :: responses[id] ? response -> 
        if
        :: response == ACCEPT -> 
            subscribersStatus[id] = UNSUBSCRIBED;
            printf("Subsriber %d released!", id);
            break;
        :: else -> skip;
        fi
    od
}

proctype subscriptionManager(short id){
    mtype:subscriberRequest request;

    do
    :: requests[id] ? request -> 
        if
        :: request == ENROLL ->
            if
            :: subscribersStatus[id] == UNSUBSCRIBED -> responses[id] ! ACCEPT;
            :: else -> responses[id] ! REJECT;
            fi
        :: request == RELEASE ->
            if
            :: subscribersStatus[id] == SUBSCRIBED -> responses[id] ! ACCEPT;
            :: else -> responses[id] ! REJECT;
            fi
        fi
    od
}

proctype timer(){
    do
    :: timeCounter++;
    od
}

init{
    timeCounter = 0;

    atomic {
        run timer();
        run publisher();
        
        int i;
        do
        :: i < subscribersCount ->
            run subscriptionManager(i);
            run subscriber(i);
            run enroll(i);
            i++;
        :: i >= subscribersCount -> break;
        od
    }
}